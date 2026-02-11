'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { signUp, confirmSignUp } from 'aws-amplify/auth'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { CheckSquare } from 'lucide-react'
import { toast } from 'sonner'
import Link from 'next/link'

export default function SignupPage() {
  const router = useRouter()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [name, setName] = useState('')
  const [confirmationCode, setConfirmationCode] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const [needsConfirmation, setNeedsConfirmation] = useState(false)

  const handleSignup = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsLoading(true)

    try {
      await signUp({
        username: email,
        password,
        options: {
          userAttributes: {
            email,
            name,
          },
        },
      })
      toast.success('Verification code sent to your email')
      setNeedsConfirmation(true)
    } catch (error: any) {
      toast.error(error.message || 'Signup failed')
    } finally {
      setIsLoading(false)
    }
  }

  const handleConfirm = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsLoading(true)

    try {
      await confirmSignUp({ username: email, confirmationCode })
      toast.success('Account confirmed! Please sign in')
      router.push('/login')
    } catch (error: any) {
      toast.error(error.message || 'Confirmation failed')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-primary/10 via-background to-secondary/10">
      <Card className="w-full max-w-md">
        <CardHeader className="space-y-1 text-center">
          <div className="flex justify-center mb-4">
            <CheckSquare className="h-12 w-12 text-primary" />
          </div>
          <CardTitle className="text-2xl font-bold">
            {needsConfirmation ? 'Verify Your Email' : 'Create Account'}
          </CardTitle>
          <p className="text-sm text-muted-foreground">
            {needsConfirmation
              ? 'Enter the verification code sent to your email'
              : 'Sign up to start managing your tasks'}
          </p>
        </CardHeader>
        <CardContent>
          {!needsConfirmation ? (
            <form onSubmit={handleSignup} className="space-y-4">
              <div className="space-y-2">
                <label htmlFor="name" className="text-sm font-medium">
                  Name
                </label>
                <Input
                  id="name"
                  type="text"
                  placeholder="John Doe"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  required
                />
              </div>

              <div className="space-y-2">
                <label htmlFor="email" className="text-sm font-medium">
                  Email
                </label>
                <Input
                  id="email"
                  type="email"
                  placeholder="you@example.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                />
              </div>

              <div className="space-y-2">
                <label htmlFor="password" className="text-sm font-medium">
                  Password
                </label>
                <Input
                  id="password"
                  type="password"
                  placeholder="••••••••"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                />
                <p className="text-xs text-muted-foreground">
                  Min 8 characters, uppercase, lowercase, number
                </p>
              </div>

              <Button type="submit" className="w-full" disabled={isLoading}>
                {isLoading ? 'Creating account...' : 'Sign Up'}
              </Button>
            </form>
          ) : (
            <form onSubmit={handleConfirm} className="space-y-4">
              <div className="space-y-2">
                <label htmlFor="code" className="text-sm font-medium">
                  Verification Code
                </label>
                <Input
                  id="code"
                  type="text"
                  placeholder="123456"
                  value={confirmationCode}
                  onChange={(e) => setConfirmationCode(e.target.value)}
                  required
                />
              </div>

              <Button type="submit" className="w-full" disabled={isLoading}>
                {isLoading ? 'Verifying...' : 'Verify Email'}
              </Button>
            </form>
          )}

          <div className="mt-4 text-center text-sm">
            <span className="text-muted-foreground">Already have an account? </span>
            <Link href="/login" className="text-primary hover:underline font-medium">
              Sign in
            </Link>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
