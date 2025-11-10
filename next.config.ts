/** @type {import('next').NextConfig} */
const nextConfig = {
  // This is the key setting for GitHub Pages
  output: 'export', 
  
  // Optional: Add the base path for GitHub Pages URL structure
  // Replace 'my-workout-tracker' with your repository name if it's different
  basePath: '/my-workout-tracker', 
  
  // Optional: Disable image optimization since GitHub Pages won't support it
  images: {
    unoptimized: true,
  },
};

module.exports = nextConfig;