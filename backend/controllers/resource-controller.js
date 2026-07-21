const Resource = require('../collections/Resource');

// GET /api/resources/course/:courseId — public
async function getCourseResources(req, res) {
  try {
    const resources = await Resource.find({ courseId: req.params.courseId })
      .populate('userId', 'username')
      .sort({ createdAt: -1 });
    res.json(resources);
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch resources', error: err.message });
  }
}

// POST /api/resources  body: { courseId, title, url }
async function createResource(req, res) {
  try {
    const { courseId, title, url } = req.body;
    if (!courseId || !title || !url) {
      return res.status(400).json({ message: 'courseId, title, and url are required' });
    }

    const resource = await Resource.create({ courseId, userId: req.user._id, title, url });
    const populated = await resource.populate('userId', 'username');
    res.status(201).json(populated);
  } catch (err) {
    res.status(400).json({ message: 'Failed to add resource', error: err.message });
  }
}

// DELETE /api/resources/:id
async function deleteResource(req, res) {
  try {
    const resource = await Resource.findById(req.params.id);
    if (!resource) {
      return res.status(404).json({ message: 'Resource not found' });
    }
    if (resource.userId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Not authorized to delete this resource' });
    }

    await resource.deleteOne();
    res.json({ message: 'Resource deleted' });
  } catch (err) {
    res.status(400).json({ message: 'Failed to delete resource', error: err.message });
  }
}

module.exports = { getCourseResources, createResource, deleteResource };
