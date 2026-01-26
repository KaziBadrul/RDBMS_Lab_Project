import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        darkRed: "#780000",
        red: "#c1121f",
        cream: "#fdf0d5",
        navy: "#003049",
        blue: "#669bbc",
      },
    },
  },
  plugins: [],
};

export default config;
