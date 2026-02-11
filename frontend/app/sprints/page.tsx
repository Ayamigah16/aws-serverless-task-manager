'use client'

import { useState } from 'react'
import { DashboardLayout } from '@/components/layout/dashboard-layout'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Plus } from 'lucide-react'
import { toast } from 'sonner'

export default function SprintsPage() {
  const [showCreate, setShowCreate] = useState(false)
  const [newSprint, setNewSprint] = useState({ name: '', goal: '', startDate: '', endDate: '' })

  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <h1 className="text-3xl font-bold">Sprints</h1>
          <Button onClick={() => setShowCreate(true)}>
            <Plus className="h-4 w-4 mr-2" />
            New Sprint
          </Button>
        </div>

        {showCreate && (
          <Card>
            <CardHeader>
              <CardTitle>Create Sprint</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <label className="text-sm font-medium">Name</label>
                <Input
                  value={newSprint.name}
                  onChange={(e) => setNewSprint({ ...newSprint, name: e.target.value })}
                  placeholder="Sprint 1"
                />
              </div>
              <div>
                <label className="text-sm font-medium">Goal</label>
                <Input
                  value={newSprint.goal}
                  onChange={(e) => setNewSprint({ ...newSprint, goal: e.target.value })}
                  placeholder="Sprint goal"
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-sm font-medium">Start Date</label>
                  <Input
                    type="date"
                    value={newSprint.startDate}
                    onChange={(e) => setNewSprint({ ...newSprint, startDate: e.target.value })}
                  />
                </div>
                <div>
                  <label className="text-sm font-medium">End Date</label>
                  <Input
                    type="date"
                    value={newSprint.endDate}
                    onChange={(e) => setNewSprint({ ...newSprint, endDate: e.target.value })}
                  />
                </div>
              </div>
              <div className="flex gap-2">
                <Button onClick={() => toast.info('Sprint creation coming soon')}>Create</Button>
                <Button variant="outline" onClick={() => setShowCreate(false)}>Cancel</Button>
              </div>
            </CardContent>
          </Card>
        )}

        <div className="text-center py-12 text-muted-foreground">
          <p>No sprints yet. Create one to get started!</p>
        </div>
      </div>
    </DashboardLayout>
  )
}
