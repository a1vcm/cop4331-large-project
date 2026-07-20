// controllers/users-controller.js
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('../collections/User');
const Review = require('../collections/Review');
const Course = require('../collections/Course');
const Vote = require('../collections/Vote');
const { sendEmail } = require('../utils/mailer');
const { generateCode, minutesFromNow } = require('../utils/codes');

const EMAIL_CHANGE_CODE_TTL_MIN = 15;

function emailChangeEmail(code) {
  return {
    subject: 'Confirm your new KnightRate email',
    text: `Your KnightRate email change code is ${code}. It expires in ${EMAIL_CHANGE_CODE_TTL_MIN} minutes. If you didn't request this, you can ignore this email.`,
    html: `<p>Your KnightRate email change code is <strong>${code}</strong>.</p><p>It expires in ${EMAIL_CHANGE_CODE_TTL_MIN} minutes. If you didn't request this, you can ignore this email.</p>`,
  };
}

// Mirrors updateCourseStats in review-controller.js — recalculates a
// course's cached rating stats after its reviews change. Duplicated here
// (rather than exported from review-controller) to keep this feature's
// changes contained to new files. If it ever changes there, change it here.
async function updateCourseStats(courseId) {
  try {
    const courseObjectId = new mongoose.Types.ObjectId(courseId);
    const stats = await Review.aggregate([
      { $match: { courseId: courseObjectId } },
      {
        $group: {
          _id: '$courseId',
          numRatings: { $sum: 1 },
          avgRating: { $avg: '$quality' },
          avgDifficulty: { $avg: '$difficulty' },
        },
      },
    ]);

    if (stats.length > 0) {
      await Course.findByIdAndUpdate(courseId, {
        numRatings: stats[0].numRatings,
        avgRating: Math.round(stats[0].avgRating * 10) / 10,
        avgDifficulty: Math.round(stats[0].avgDifficulty * 10) / 10,
      });
    } else {
      await Course.findByIdAndUpdate(courseId, {
        numRatings: 0,
        avgRating: 0,
        avgDifficulty: 0,
      });
    }
  } catch (err) {
    console.error(`[stats-aggregation] Error updating course ${courseId}:`, err.message);
  }
}

// PUT /api/users/username
async function changeUsername(req, res) {
  try {
    const { username } = req.body;
    if (!username || !username.trim()) {
      return res.status(400).json({ message: 'username is required' });
    }

    req.user.username = username.trim();
    await req.user.save();

    res.json({ message: 'Username updated', username: req.user.username });
  } catch (err) {
    res.status(500).json({ message: 'Failed to update username', error: err.message });
  }
}

// POST /api/users/email/request
async function requestEmailChange(req, res) {
  try {
    const { newEmail } = req.body;
    if (!newEmail) {
      return res.status(400).json({ message: 'newEmail is required' });
    }

    const normalized = newEmail.toLowerCase().trim();
    if (normalized === req.user.email) {
      return res.status(400).json({ message: 'That is already your email address' });
    }

    const existing = await User.findOne({ email: normalized });
    if (existing) {
      return res.status(409).json({ message: 'An account with that email already exists' });
    }

    const code = generateCode();
    req.user.pendingEmail = normalized;
    req.user.verificationCode = code;
    req.user.verificationCodeExpires = minutesFromNow(EMAIL_CHANGE_CODE_TTL_MIN);
    await req.user.save();

    // The code goes to the NEW address — proves the user controls it.
    await sendEmail({ to: normalized, ...emailChangeEmail(code) });

    res.json({ message: 'Verification code sent to the new email address' });
  } catch (err) {
    res.status(500).json({ message: 'Failed to request email change', error: err.message });
  }
}

// POST /api/users/email/verify
async function verifyEmailChange(req, res) {
  try {
    const { code } = req.body;
    if (!code) {
      return res.status(400).json({ message: 'code is required' });
    }

    if (!req.user.pendingEmail) {
      return res.status(400).json({ message: 'No email change is pending' });
    }

    const isExpired =
      !req.user.verificationCodeExpires || req.user.verificationCodeExpires < new Date();
    if (req.user.verificationCode !== code || isExpired) {
      return res.status(400).json({ message: 'Invalid or expired verification code' });
    }

    // Re-check uniqueness in case someone registered this address between
    // request and verify. The unique index would reject it anyway, but this
    // gives a clean message instead of a duplicate-key error.
    const taken = await User.findOne({ email: req.user.pendingEmail, _id: { $ne: req.user._id } });
    if (taken) {
      return res.status(409).json({ message: 'An account with that email already exists' });
    }

    req.user.email = req.user.pendingEmail;
    req.user.pendingEmail = undefined;
    req.user.verificationCode = undefined;
    req.user.verificationCodeExpires = undefined;
    await req.user.save();

    res.json({ message: 'Email updated', email: req.user.email });
  } catch (err) {
    res.status(500).json({ message: 'Failed to verify email change', error: err.message });
  }
}

// PUT /api/users/password
async function changePassword(req, res) {
  try {
    const { currentPassword, newPassword } = req.body;
    if (!currentPassword || !newPassword) {
      return res.status(400).json({ message: 'currentPassword and newPassword are required' });
    }

    // protect strips passwordHash from req.user, so re-fetch it.
    const user = await User.findById(req.user._id);
    const valid = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!valid) {
      return res.status(401).json({ message: 'Current password is incorrect' });
    }

    user.passwordHash = await bcrypt.hash(newPassword, 10);
    await user.save();

    res.json({ message: 'Password changed' });
  } catch (err) {
    res.status(500).json({ message: 'Failed to change password', error: err.message });
  }
}

// DELETE /api/users/me
async function deleteAccount(req, res) {
  try {
    const { password } = req.body;
    if (!password) {
      return res.status(400).json({ message: 'password is required' });
    }

    const user = await User.findById(req.user._id);
    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) {
      return res.status(401).json({ message: 'Password is incorrect' });
    }

    // Cascade, in dependency order:

    // 1. The user's reviews (and which courses they touch)
    const myReviews = await Review.find({ userId: user._id }).select('_id courseId');
    const myReviewIds = myReviews.map((r) => r._id);
    const affectedCourseIds = [...new Set(myReviews.map((r) => r.courseId.toString()))];

    // 2. Votes OTHER users cast on those reviews (orphaned once reviews go)
    await Vote.deleteMany({ reviewId: { $in: myReviewIds } });

    // 3. Votes THIS user cast on other people's reviews — undo each one's
    //    effect on the review's cached voteScore, then delete them.
    const myVotes = await Vote.find({ userId: user._id });
    if (myVotes.length > 0) {
      await Review.bulkWrite(
        myVotes.map((vote) => ({
          updateOne: {
            filter: { _id: vote.reviewId },
            update: {
              $inc:
                vote.value === 1
                  ? { 'voteScore.helpful': -1 }
                  : { 'voteScore.notHelpful': -1 },
            },
          },
        }))
      );
      await Vote.deleteMany({ userId: user._id });
    }

    // 4. The reviews themselves, then refresh each affected course's stats
    await Review.deleteMany({ userId: user._id });
    for (const courseId of affectedCourseIds) {
      await updateCourseStats(courseId);
    }

    // 5. Finally the user
    await user.deleteOne();

    res.json({ message: 'Account deleted' });
  } catch (err) {
    res.status(500).json({ message: 'Failed to delete account', error: err.message });
  }
}

module.exports = {
  changeUsername,
  requestEmailChange,
  verifyEmailChange,
  changePassword,
  deleteAccount,
};
