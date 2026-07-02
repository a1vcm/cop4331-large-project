// Design tokens for the frontend, based on the brand style guide.
export const C = 
{
  gold: "#F2C417", goldDark: "#BD9A36", goldLight: "#F5D77A", goldPale: "#FBEBBE",
  black: "#1A1A1A", grayDark: "#333333", grayMedium: "#555555", grayLight: "#888888", grayLighter: "#BBBBBB", grayLightest: "#EAEAEA", 
  white: "#FFFFFF",
};

//Font
export const F = 
{
  display: '"Knockout", "Helvetica Neue", Arial, sans-serif',
  heading: '"Gotham", "Helvetica Neue", Arial, sans-serif',
  body: '"Helvetica Neue", Arial, sans-serif', 
};

//Font-weight
export const fW = {
  regular: 400,
  medium: 500,
  bold: 700,
};

//Spacing
export const S = {
  xs: "4px",
  sm: "8px",
  md: "16px",
  lg: "24px",
  xl: "40px",
};

// Theme object combining all aspects of the design system for easy access in components.
//When importing, import T. 
export const T = {
  C,
  F,
  fW,
  S,

  primary: C.gold,
  onPrimary: C.black,
  text: C.black,
  textMuted: C.grayMedium,
  background: C.white,
  surface: C.grayLightest,
  border: C.grayLight,
};

export default T;
