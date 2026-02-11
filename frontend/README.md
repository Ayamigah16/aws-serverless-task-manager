# TaskFlow - Modern Task Management Frontend

Next.js 14 application with TypeScript, Tailwind CSS, and AWS Amplify integration.

## Tech Stack

- **Framework**: Next.js 14 (App Router)
- **Language**: TypeScript
- **Styling**: Tailwind CSS + shadcn/ui
- **State Management**: Zustand + TanStack Query
- **Authentication**: AWS Amplify (Cognito)
- **API**: GraphQL (AppSync) + REST (API Gateway)
- **Icons**: Lucide React
- **Animations**: Framer Motion
- **Forms**: React Hook Form + Zod

## Getting Started

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Environment

Copy `.env.local.example` to `.env.local` and fill in your AWS values:

```bash
cp .env.local.example .env.local
```

### 3. Run Development Server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000)

## Project Structure

```
frontend/
├── app/                    # Next.js App Router pages
│   ├── dashboard/         # Dashboard page
│   ├── tasks/            # Tasks list/board
│   ├── login/            # Authentication
│   ├── layout.tsx        # Root layout
│   └── globals.css       # Global styles
├── components/
│   ├── ui/               # Base UI components (shadcn/ui)
│   ├── layout/           # Layout components (Sidebar, Header)
│   ├── tasks/            # Task-specific components
│   ├── common/           # Shared components
│   └── providers.tsx     # App providers
├── lib/
│   ├── hooks/            # Custom React hooks
│   ├── stores/           # Zustand stores
│   ├── utils/            # Utility functions
│   └── amplify-config.ts # AWS Amplify configuration
└── public/               # Static assets
```

## Key Features

### Authentication
- AWS Cognito integration
- Protected routes
- Role-based access (Admin/Member)

### Task Management
- List, Board, Calendar views
- Real-time updates via AppSync subscriptions
- Drag-and-drop (board view)
- Inline editing
- File attachments

### UI/UX
- Dark mode support
- Responsive design (mobile-first)
- Keyboard shortcuts
- Toast notifications
- Loading states & skeletons

### Performance
- Server-side rendering (SSR)
- Optimistic updates
- Query caching (React Query)
- Code splitting
- Image optimization

## Available Scripts

```bash
npm run dev          # Start development server
npm run build        # Build for production
npm run start        # Start production server
npm run lint         # Run ESLint
npm run type-check   # TypeScript type checking
```

## Component Usage

### Button
```tsx
import { Button } from '@/components/ui/button'

<Button variant="default">Click me</Button>
<Button variant="outline" size="sm">Small</Button>
```

### Card
```tsx
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card'

<Card>
  <CardHeader>
    <CardTitle>Title</CardTitle>
  </CardHeader>
  <CardContent>Content</CardContent>
</Card>
```

### Badge
```tsx
import { Badge } from '@/components/ui/badge'

<Badge variant="high">High Priority</Badge>
<Badge variant="low">Low Priority</Badge>
```

## State Management

### Auth Store
```tsx
import { useAuthStore } from '@/lib/stores/auth-store'

const { user, isAuthenticated, logout } = useAuthStore()
```

### UI Store
```tsx
import { useUIStore } from '@/lib/stores/ui-store'

const { sidebarCollapsed, toggleSidebar, viewMode, setViewMode } = useUIStore()
```

## Data Fetching

### Using React Query
```tsx
import { useTasks } from '@/lib/hooks/use-tasks'

const { data, isLoading, error } = useTasks('OPEN')
```

### Creating Tasks
```tsx
import { useCreateTask } from '@/lib/hooks/use-tasks'

const createTask = useCreateTask()

createTask.mutate({
  title: 'New Task',
  priority: 'HIGH',
  status: 'OPEN'
})
```

## Styling

### Tailwind Classes
```tsx
<div className="flex items-center gap-4 p-6 rounded-lg bg-card">
  <h1 className="text-2xl font-bold">Title</h1>
</div>
```

### Custom Utilities
```tsx
import { cn } from '@/lib/utils'

<div className={cn('base-class', isActive && 'active-class')} />
```

## Deployment

### Build
```bash
npm run build
```

### Deploy to AWS Amplify
```bash
# Connect your GitHub repo to Amplify Console
# Or use Amplify CLI
amplify publish
```

### Deploy to Vercel
```bash
vercel --prod
```

## Environment Variables

Required variables:
- `NEXT_PUBLIC_USER_POOL_ID` - Cognito User Pool ID
- `NEXT_PUBLIC_USER_POOL_CLIENT_ID` - Cognito Client ID
- `NEXT_PUBLIC_APPSYNC_ENDPOINT` - AppSync GraphQL endpoint
- `NEXT_PUBLIC_API_ENDPOINT` - API Gateway REST endpoint
- `NEXT_PUBLIC_S3_BUCKET` - S3 bucket for attachments
- `NEXT_PUBLIC_AWS_REGION` - AWS region

## Performance Optimization

- Use `next/image` for images
- Lazy load components with `dynamic()`
- Implement virtual scrolling for long lists
- Enable React Query caching
- Use Suspense boundaries

## Accessibility

- Semantic HTML
- ARIA labels
- Keyboard navigation
- Focus management
- Screen reader support

## Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)

## License

MIT
