import './Footer.css';

function Footer() {
  return (
    <footer className="site-footer">
      <p className="site-footer-text">© {new Date().getFullYear()} made by the KnightRate team</p>
    </footer>
  );
}

export default Footer;
