'use client'

import { useState } from 'react'
import { DashboardLayout } from '@/components/layout/dashboard-layout'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Plus } from 'lucide-react'
import { toast } from 'sonner'

export default function ProjectsPage() {
  const [showCreate, setShowCreate] = useState(false)
  const [newProject, setNewProject] = useState({ name: '', description: '', key: '' })

  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <h1 className="text-3xl font-bold">Projects</h1>
          <Button onClick={() => setShowCreate(true)}>
            <Plus className="h-4 w-4 mr-2" />
            New Project
          </Button>
        </div>

        {showCreate && (
          <Card>
            <CardHeader>
              <CardTitle>Create Project</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <label className="text-sm font-medium">Name</label>
                <Input
                  value={newProject.name}
                  onChange={(e) => setNewProject({ ...newProject, name: e.target.value })}
                  placeholder="Project name"
                />
              </div>
              <div>
                <label className="text-sm font-medium">Key</label>
                <Input
                  value={newProject.key}
                  onChange={(e) => setNewProject({ ...newProject, key: e.target.value.toUpperCase() })}
                  placeholder="PROJ"
                  maxLength={10}
                />
              </div>
              <div>
                <label className="text-sm font-medium">Description</label>
                <Input
                  value={newProject.description}
                  onChange={(e) => setNewProject({ ...newProject, description: e.target.value })}
                  placeholder="Project description"
                />
              </div>
              <div className="flex gap-2">
                <Button onClick={() => toast.info('Project creation coming soon')}>Create</Button>
                <Button variant="outline" onClick={() => setShowCreate(false)}>Cancel</Button>
              </div>
            </CardContent>
          </Card>
        )}

        <div className="text-center py-12 text-muted-foreground">
          <p>No projects yet. Create one to get started!</p>
        </div>
      </div>
    </DashboardLayout>
  )
}
