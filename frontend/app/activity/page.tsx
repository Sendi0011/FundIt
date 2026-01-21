"use client"

import { Navbar } from "@/components/navbar"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Badge } from "@/components/ui/badge"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { useActivity } from "@/lib/hooks/use-activity"
import { 
  ArrowDownLeft, 
  ArrowUpRight, 
  Zap, 
  CheckCircle2, 
  Clock, 
  AlertCircle, 
  Download,
  Search,
  Filter,
  TrendingUp,
  Wallet,
  Settings,
  Shield,
  RefreshCw,
  Eye,
  Calendar,
  DollarSign,
  ChevronDown
} from "lucide-react"
import { useState, useMemo } from "react"

export default function ActivityPage() {
  const { activities } = useActivity()
  const [searchTerm, setSearchTerm] = useState("")
  const [statusFilter, setStatusFilter] = useState<"all" | "pending" | "confirmed" | "failed">("all")
  const [typeFilter, setTypeFilter] = useState<"all" | "deposit" | "withdraw" | "spend-save" | "vault-created" | "config-updated">("all")

  const filteredActivities = useMemo(() => {
    return activities.filter((activity) => {
      const matchesSearch =
        activity.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
        activity.description.toLowerCase().includes(searchTerm.toLowerCase())
      const matchesStatus = statusFilter === "all" || activity.status === statusFilter
      const matchesType = typeFilter === "all" || activity.type === typeFilter
      return matchesSearch && matchesStatus && matchesType
    })
  }, [activities, searchTerm, statusFilter, typeFilter])

  const getIcon = (type: string) => {
    switch (type) {
      case "deposit":
        return <ArrowDownLeft className="h-5 w-5 text-green-500" />
      case "withdraw":
        return <ArrowUpRight className="h-5 w-5 text-orange-500" />
      case "spend-save":
        return <Zap className="h-5 w-5 text-blue-500" />
      case "vault-created":
        return <Shield className="h-5 w-5 text-purple-500" />
      case "config-updated":
        return <Settings className="h-5 w-5 text-indigo-500" />
      default:
        return <AlertCircle className="h-5 w-5 text-gray-500" />
    }
  }

  const getTypeDescription = (type: string) => {
    switch (type) {
      case "deposit":
        return "Funds added to your vault"
      case "withdraw":
        return "Funds withdrawn from vault"
      case "spend-save":
        return "Automatic savings from spending"
      case "vault-created":
        return "New savings vault created"
      case "config-updated":
        return "Savings configuration updated"
      default:
        return "Transaction activity"
    }
  }

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "confirmed":
        return (
          <Badge variant="secondary" className="bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-200 animate-pulse">
            <CheckCircle2 className="h-3 w-3 mr-1" />
            Confirmed
          </Badge>
        )
      case "pending":
        return (
          <Badge variant="secondary" className="bg-amber-100 text-amber-700 dark:bg-amber-900 dark:text-amber-200">
            <RefreshCw className="h-3 w-3 mr-1 animate-spin" />
            Pending
          </Badge>
        )
      case "failed":
        return (
          <Badge variant="destructive" className="animate-pulse">
            <AlertCircle className="h-3 w-3 mr-1" />
            Failed
          </Badge>
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
      <div className="min-h-screen bg-gradient-to-b from-background to-background/50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-8">
          {/* Header */}
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 animate-fade-in">
            <div>
              <h1 className="text-2xl sm:text-3xl font-bold flex items-center gap-2 sm:gap-3">
                <Eye className="h-6 w-6 sm:h-8 sm:w-8 text-primary" />
                Activity History
              </h1>
              <p className="text-muted-foreground mt-1 text-sm sm:text-base">Track all your transactions and auto-saves</p>
            </div>
            <Button className="gap-2 hover:scale-105 transition-transform w-full sm:w-auto">
              <Download className="h-4 w-4" />
              Export CSV
            </Button>
          </div>

          {/* Stats Cards */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            <Card className="hover:shadow-lg transition-all duration-300 hover:scale-105">
              <CardHeader className="pb-3">
                <CardTitle className="text-sm font-medium flex items-center gap-2">
                  <div className="p-2 bg-green-100 dark:bg-green-900 rounded-full">
                    <ArrowDownLeft className="h-3 w-3 sm:h-4 sm:w-4 text-green-600 dark:text-green-400" />
                  </div>
                  <span className="text-xs sm:text-sm">Total Deposited</span>
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-xl sm:text-2xl font-bold text-green-600 dark:text-green-400">
                  {totalDeposits.toFixed(2)} USDC
                </div>
                <p className="text-xs text-muted-foreground mt-1 flex items-center gap-1">
                  <TrendingUp className="h-3 w-3" />
                  {activities.filter((a) => a.type === "deposit").length} deposits
                </p>
              </CardContent>
            </Card>

            <Card className="hover:shadow-lg transition-all duration-300 hover:scale-105">
              <CardHeader className="pb-3">
                <CardTitle className="text-sm font-medium flex items-center gap-2">
                  <div className="p-2 bg-blue-100 dark:bg-blue-900 rounded-full">
                    <Zap className="h-3 w-3 sm:h-4 sm:w-4 text-blue-600 dark:text-blue-400" />
                  </div>
                  <span className="text-xs sm:text-sm">Auto-Saved</span>
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-xl sm:text-2xl font-bold text-blue-600 dark:text-blue-400">
                  {totalAutoSaved.toFixed(2)} USDC
                </div>
                <p className="text-xs text-muted-foreground mt-1 flex items-center gap-1">
                  <Shield className="h-3 w-3" />
                  {activities.filter((a) => a.type === "spend-save").length} auto-saves
                </p>
              </CardContent>
            </Card>

            <Card className="hover:shadow-lg transition-all duration-300 hover:scale-105 sm:col-span-2 lg:col-span-1">
              <CardHeader className="pb-3">
                <CardTitle className="text-sm font-medium flex items-center gap-2">
                  <div className="p-2 bg-orange-100 dark:bg-orange-900 rounded-full">
                    <ArrowUpRight className="h-3 w-3 sm:h-4 sm:w-4 text-orange-600 dark:text-orange-400" />
                  </div>
                  <span className="text-xs sm:text-sm">Total Withdrawn</span>
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-xl sm:text-2xl font-bold text-orange-600 dark:text-orange-400">
                  {totalWithdrawals.toFixed(2)} USDC
                </div>
                <p className="text-xs text-muted-foreground mt-1 flex items-center gap-1">
                  <Wallet className="h-3 w-3" />
                  {activities.filter((a) => a.type === "withdraw").length} withdrawals
                </p>
              </CardContent>
            </Card>
          </div>

          {/* Enhanced Filters & Search */}
          <Card className="hover:shadow-md transition-shadow">
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-lg sm:text-xl">
                <Filter className="h-4 w-4 sm:h-5 sm:w-5 text-primary" />
                Filter Activities
              </CardTitle>
              <CardDescription className="text-sm">Search and filter your transaction history</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              {/* Search */}
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Search activities..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-10 transition-all focus:ring-2 focus:ring-primary/20"
                />
              </div>
              
              {/* Filters Row */}
              <div className="flex flex-col sm:flex-row gap-3 sm:gap-4">
                {/* Status Filter Dropdown */}
                <div className="flex-1 sm:flex-none sm:min-w-[140px]">
                  <Select value={statusFilter} onValueChange={(value: any) => setStatusFilter(value)}>
                    <SelectTrigger className="w-full">
                      <div className="flex items-center gap-2">
                        {statusFilter === "confirmed" && <CheckCircle2 className="h-3 w-3" />}
                        {statusFilter === "pending" && <Clock className="h-3 w-3" />}
                        {statusFilter === "failed" && <AlertCircle className="h-3 w-3" />}
                        <SelectValue placeholder="Status" />
                      </div>
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All Status</SelectItem>
                      <SelectItem value="confirmed">
                        <div className="flex items-center gap-2">
                          <CheckCircle2 className="h-3 w-3" />
                          Confirmed
                        </div>
                      </SelectItem>
                      <SelectItem value="pending">
                        <div className="flex items-center gap-2">
                          <Clock className="h-3 w-3" />
                          Pending
                        </div>
                      </SelectItem>
                      <SelectItem value="failed">
                        <div className="flex items-center gap-2">
                          <AlertCircle className="h-3 w-3" />
                          Failed
                        </div>
                      </SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                {/* Type Filter Dropdown */}
                <div className="flex-1 sm:flex-none sm:min-w-[140px]">
                  <Select value={typeFilter} onValueChange={(value: any) => setTypeFilter(value)}>
                    <SelectTrigger className="w-full">
                      <div className="flex items-center gap-2">
                        {typeFilter === "deposit" && <ArrowDownLeft className="h-3 w-3" />}
                        {typeFilter === "withdraw" && <ArrowUpRight className="h-3 w-3" />}
                        {typeFilter === "spend-save" && <Zap className="h-3 w-3" />}
                        {typeFilter === "vault-created" && <Shield className="h-3 w-3" />}
                        {typeFilter === "config-updated" && <Settings className="h-3 w-3" />}
                        <SelectValue placeholder="Type" />
                      </div>
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All Types</SelectItem>
                      <SelectItem value="deposit">
                        <div className="flex items-center gap-2">
                          <ArrowDownLeft className="h-3 w-3" />
                          Deposits
                        </div>
                      </SelectItem>
                      <SelectItem value="withdraw">
                        <div className="flex items-center gap-2">
                          <ArrowUpRight className="h-3 w-3" />
                          Withdrawals
                        </div>
                      </SelectItem>
                      <SelectItem value="spend-save">
                        <div className="flex items-center gap-2">
                          <Zap className="h-3 w-3" />
                          Auto-Save
                        </div>
                      </SelectItem>
                      <SelectItem value="vault-created">
                        <div className="flex items-center gap-2">
                          <Shield className="h-3 w-3" />
                          Vault
                        </div>
                      </SelectItem>
                      <SelectItem value="config-updated">
                        <div className="flex items-center gap-2">
                          <Settings className="h-3 w-3" />
                          Config
                        </div>
                      </SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                {/* Clear Filters Button */}
                <Button 
                  variant="outline" 
                  size="sm"
                  onClick={() => {
                    setSearchTerm("")
                    setStatusFilter("all")
                    setTypeFilter("all")
                  }}
                  className="w-full sm:w-auto"
                >
                  Clear Filters
                </Button>
              </div>
            </CardContent>
          </Card>

          {/* Activities List */}
          <Card className="hover:shadow-md transition-shadow">
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-lg sm:text-xl">
                <Calendar className="h-4 w-4 sm:h-5 sm:w-5 text-primary" />
                Transactions
              </CardTitle>
              <CardDescription className="text-sm">
                {filteredActivities.length} of {activities.length} activities found
              </CardDescription>
            </CardHeader>
            <CardContent>
              {filteredActivities.length === 0 ? (
                <div className="text-center py-8 sm:py-12 animate-fade-in">
                  <div className="p-3 sm:p-4 bg-muted/50 rounded-full w-12 h-12 sm:w-16 sm:h-16 mx-auto mb-4 flex items-center justify-center">
                    <AlertCircle className="h-6 w-6 sm:h-8 sm:w-8 text-muted-foreground" />
                  </div>
                  <p className="text-muted-foreground text-base sm:text-lg font-medium">No activities found</p>
                  <p className="text-xs sm:text-sm text-muted-foreground mt-1">Try adjusting your filters</p>
                </div>
              ) : (
                <div className="space-y-3">
                  {filteredActivities.map((activity, index) => (
                    <div
                      key={activity.id}
                      className="group flex flex-col sm:flex-row sm:items-center justify-between p-3 sm:p-4 border rounded-lg hover:bg-muted/50 hover:shadow-md transition-all duration-300 hover:scale-[1.02] animate-slide-in gap-3 sm:gap-4"
                      style={{ animationDelay: `${index * 50}ms` }}
                    >
                      <div className="flex items-center gap-3 sm:gap-4 flex-1">
                        <div className="h-10 w-10 sm:h-12 sm:w-12 rounded-xl bg-gradient-to-br from-muted to-muted/50 flex items-center justify-center flex-shrink-0 group-hover:scale-110 transition-transform">
                          {getIcon(activity.type)}
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="flex flex-col sm:flex-row sm:items-center gap-1 sm:gap-2 mb-1">
                            <p className="font-semibold text-sm truncate">{activity.title}</p>
                            <Badge variant="outline" className="text-xs w-fit">
                              {activity.type.replace("-", " ")}
                            </Badge>
                          </div>
                          <p className="text-xs text-muted-foreground mb-1 line-clamp-2">
                            {activity.description || getTypeDescription(activity.type)}
                          </p>
                          <div className="flex flex-col sm:flex-row sm:items-center gap-1 sm:gap-2 text-xs text-muted-foreground">
                            <div className="flex items-center gap-1">
                              <Calendar className="h-3 w-3" />
                              {activity.timestamp.toLocaleDateString()}
                            </div>
                            <div className="flex items-center gap-1">
                              <Clock className="h-3 w-3" />
                              {activity.timestamp.toLocaleTimeString()}
                            </div>
                          </div>
                        </div>
                      </div>
                      <div className="flex sm:flex-col items-center sm:items-end justify-between sm:justify-center gap-2 sm:gap-2 flex-shrink-0">
                        {activity.amount && (
                          <div className="flex items-center gap-1">
                            <DollarSign className="h-3 w-3" />
                            <p
                              className={`font-bold text-sm ${
                                activity.type === "withdraw" 
                                  ? "text-orange-600 dark:text-orange-400" 
                                  : "text-green-600 dark:text-green-400"
                              }`}
                            >
                              {activity.type === "withdraw" ? "-" : "+"}
                              {activity.amount.toFixed(2)} USDC
                            </p>
                          </div>
                        )}
                        {getStatusBadge(activity.status)}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </div>

      <style jsx global>{`
        @keyframes fade-in {
          from { opacity: 0; transform: translateY(20px); }
          to { opacity: 1; transform: translateY(0); }
        }
        
        @keyframes slide-in {
          from { opacity: 0; transform: translateX(-20px); }
          to { opacity: 1; transform: translateX(0); }
        }
        
        .animate-fade-in {
          animation: fade-in 0.6s ease-out;
        }
        
        .animate-slide-in {
          animation: slide-in 0.4s ease-out forwards;
          opacity: 0;
        }
      `}</style>
    </>
  )
}
