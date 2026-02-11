/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: {
    domains: ['task-manager-sandbox-attachments.s3.amazonaws.com'],
  },
  experimental: {
    optimizePackageImports: ['lucide-react', '@aws-amplify/ui-react'],
  },
}

module.exports = nextConfig
