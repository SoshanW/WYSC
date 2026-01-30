/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,jsx,ts,tsx}"],
  theme: {
    extend: {
      colors: {
        brand: {
          50: "#f6f5ff",
          100: "#ecebff",
          200: "#d7d4ff",
          300: "#bbb3ff",
          400: "#9c8bff",
          500: "#7b5cff",
          600: "#673de6",
          700: "#5632bf",
          800: "#44298f",
          900: "#36226d"
        }
      },
      boxShadow: {
        soft: "0 10px 30px rgba(24, 18, 43, 0.12)"
      }
    }
  },
  plugins: [],
};
