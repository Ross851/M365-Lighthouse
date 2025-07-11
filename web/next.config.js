/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // Remove static export for dynamic routes
  images: {
    unoptimized: true
  }
}

module.exports = nextConfig