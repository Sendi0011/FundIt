"use client"

import { Navbar } from "@/components/navbar"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { useActivity } from "@/lib/hooks/use-activity"
import { ArrowDownLeft, ArrowUpRight, Zap, CheckCircle2, Clock, AlertCircle, Download } from "lucide-react"
import { useState, useMemo } from "react"

export default function ActivityPage() {
  const { activities } = useActivity()
  const [searchTerm, setSearchTerm] = useState("")
  const [statusFilter, setStatusFilter] = useState<"all" | "pending" | "confirmed" | "failed">("all")

  const filteredActivities = useMemo(() => {
    return activities.filter((activity) => {
      const matchesSearch =
        activity.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
        activity.description.toLowerCase().includes(searchTerm.toLowerCase())
      const matchesStatus = statusFilter === "all" || activity.status === statusFilter
      return matchesSearch && matchesStatus
    })
  }, [activities, searchTerm, statusFilter])

  const getIcon = (type: string) => {
    switch (type) {
      case "deposit":
        return <ArrowDownLeft className="h-5 w-5 text-green-500" />
      case "withdraw":
        return <ArrowUpRight className="h-5 w-5 text-orange-500" />
      case "spend-save":
        return <Zap className="h-5 w-5 text-accent" />
      case "vault-created":
        return <CheckCircle2 className="h-5 w-5 text-blue-500" />
      case "config-updated":
        return <Clock className="h-5 w-5 text-purple-500" />
      default:
        return <AlertCircle className="h-5 w-5" />
    }
  }

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "confirmed":
        return (
          <div className="flex items-center gap-1 px-2 py-1 bg-green-100 dark:bg-green-900 rounded-full text-xs font-medium text-green-700 dark:text-green-200">
            <CheckCircle2 className="h-3 w-3" />
            Confirmed
          </div>
        )
      case "pending":
        return (
          <div className="flex items-center gap-1 px-2 py-1 bg-amber-100 dark:bg-amber-900 rounded-full text-xs font-medium text-amber-700 dark:text-amber-200">
            <Clock className="h-3 w-3" />
            Pending
          </div>
        )
      case "failed":
        return (
          <div className="flex items-center gap-1 px-2 py-1 bg-red-100 dark:bg-red-900 rounded-full text-xs font-medium text-red-700 dark:text-red-200">
            <AlertCircle className="h-3 w-3" />
            Failed
          </div>
        )
      default:
        return null
    }
  }

  const totalDeposits = activities
    .filter((a) => a.type === "deposit" && a.status === "confirmed")
    .reduce((sum, a) => sum + (a.amount || 0), 0)

  const totalWithdrawals = activities
    .filter((a) => a.type === "withdraw" && a.status === "confirmed")
    .reduce((sum, a) => sum + (a.amount || 0), 0)

  const totalAutoSaved = activities
    .filter((a) => a.type === "spend-save" && a.status === "confirmed")
    .reduce((sum, a) => sum + (a.amount || 0), 0)

  return (
    <>
      <Navbar />
      <div className="min-h-screen bg-linear-to-b from-background to-background/50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-8">
          {/* Header */}
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold">Activity History</h1>
              <p className="text-muted-foreground mt-1">Track all your transactions and auto-saves</p>
            </div>
            <Button className="gap-2">
              <Download className="h-4 w-4" />
              Export CSV
            </Button>
          </div>

          {/* Stats Cards */}
          <div className="grid md:grid-cols-3 gap-4">
            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-sm font-medium flex items-center gap-2">
                  <ArrowDownLeft className="h-4 w-4 text-green-500" />
                  Total Deposited
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{totalDeposits.toFixed(2)} USDC</div>
                <p className="text-xs text-muted-foreground mt-1">
                  {activities.filter((a) => a.type === "deposit").length} deposits
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-sm font-medium flex items-center gap-2">
                  <Zap className="h-4 w-4 text-accent" />
                  Auto-Saved
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{totalAutoSaved.toFixed(2)} USDC</div>
                <p className="text-xs text-muted-foreground mt-1">
                  {activities.filter((a) => a.type === "spend-save").length} auto-saves
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-sm font-medium flex items-center gap-2">
                  <ArrowUpRight className="h-4 w-4 text-orange-500" />
                  Total Withdrawn
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{totalWithdrawals.toFixed(2)} USDC</div>
                <p className="text-xs text-muted-foreground mt-1">
                  {activities.filter((a) => a.type === "withdraw").length} withdrawals
                </p>
              </CardContent>
            </Card>
          </div>

          {/* Filters & Search */}
          <Card>
            <CardHeader>
              <CardTitle>Filter Activities</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex gap-4 flex-col md:flex-row">
                <div className="flex-1">
                  <Input
                    placeholder="Search activities..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                  />
                </div>
                <div className="flex gap-2">
                  <Button
                    variant={statusFilter === "all" ? "default" : "outline"}
                    onClick={() => setStatusFilter("all")}
                    size="sm"
                  >
                    All
                  </Button>
                  <Button
                    variant={statusFilter === "confirmed" ? "default" : "outline"}
                    onClick={() => setStatusFilter("confirmed")}
                    size="sm"
                  >
                    Confirmed
                  </Button>
                  <Button
                    variant={statusFilter === "pending" ? "default" : "outline"}
                    onClick={() => setStatusFilter("pending")}
                    size="sm"
                  >
                    Pending
                  </Button>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Activities List */}
          <Card>
            <CardHeader>
              <CardTitle>Transactions</CardTitle>
              <CardDescription>{filteredActivities.length} activities found</CardDescription>
            </CardHeader>
            <CardContent>
              {filteredActivities.length === 0 ? (
                <div className="text-center py-8">
                  <AlertCircle className="h-8 w-8 text-muted-foreground mx-auto mb-2" />
                  <p className="text-muted-foreground">No activities found</p>
                </div>
              ) : (
                <div className="space-y-4">
                  {filteredActivities.map((activity) => (
                    <div
                      key={activity.id}
                      className="flex items-center justify-between p-4 border rounded-lg hover:bg-muted/50 transition-colors"
                    >
                      <div className="flex items-center gap-4 flex-1">
                        <div className="h-10 w-10 rounded-lg bg-muted flex items-center justify-center shrink-0">
                          {getIcon(activity.type)}
                        </div>
                        <div className="flex-1">
                          <p className="font-medium text-sm">{activity.title}</p>
                          <p className="text-xs text-muted-foreground">{activity.description}</p>
                          <p className="text-xs text-muted-foreground mt-1">
                            {activity.timestamp.toLocaleDateString()} {activity.timestamp.toLocaleTimeString()}
                          </p>
                        </div>
                      </div>
                      <div className="text-right shrink-0">
                        {activity.amount && (
                          <p
                            className={`font-bold text-sm ${activity.type === "withdraw" ? "text-orange-500" : "text-green-500"}`}
                          >
                            {activity.type === "withdraw" ? "-" : "+"}
                            {activity.amount.toFixed(2)} USDC
                          </p>
                        )}
                        <div className="mt-2">{getStatusBadge(activity.status)}</div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </div>
    </>
  )
}
