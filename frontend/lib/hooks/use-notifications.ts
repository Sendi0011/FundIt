"use client"

import { useState, useCallback } from "react"

export interface Notification {
  id: string
  type: "success" | "error" | "info" | "warning"
  title: string
  message: string
  timestamp: Date
  autoDismiss?: boolean
  duration?: number
}

// Hook for notifications
export function useNotifications() {
  const [notifications, setNotifications] = useState<Notification[]>([])

  const addNotification = useCallback((notification: Omit<Notification, "id" | "timestamp">) => {
    const newNotification: Notification = {
      ...notification,
      id: `notif_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      timestamp: new Date(),
      autoDismiss: notification.autoDismiss !== false,
      duration: notification.duration || 5000,
    }

    setNotifications((prev) => [...prev, newNotification])

    // Automated dismiss if enabled
    if (newNotification.autoDismiss) {
      setTimeout(() => {
        removeNotification(newNotification.id)
      }, newNotification.duration)
    }

    return newNotification
  }, [])

  const removeNotification = useCallback((notificationId: string) => {
    setNotifications((prev) => prev.filter((n) => n.id !== notificationId))
  }, [])

  const notifySuccess = useCallback(
    (title: string, message: string) => {
      return addNotification({
        type: "success",
        title,
        message,
      })
    },
    [addNotification],
  )

  const notifyError = useCallback(
    (title: string, message: string) => {
      return addNotification({
        type: "error",
        title,
        message,
        autoDismiss: false,
      })
    },
    [addNotification],
  )

  const notifyInfo = useCallback(
    (title: string, message: string) => {
      return addNotification({
        type: "info",
        title,
        message,
      })
    },
    [addNotification],
  )

  const notifyWarning = useCallback(
    (title: string, message: string) => {
      return addNotification({
        type: "warning",
        title,
        message,
        autoDismiss: false,
      })
    },
    [addNotification],
  )

  // Notification templates
  const notifyDepositSuccess = useCallback(
    (amount: number) => {
      return notifySuccess("Deposit Successful", `You've deposited ${amount} USDC to your savings`)
    },
    [notifySuccess],
  )

  const notifyWithdrawSuccess = useCallback(
    (amount: number) => {
      return notifySuccess("Withdrawal Successful", `You've withdrawn ${amount} USDC`)
    },
    [notifySuccess],
  )

  const notifySpendAndSaveTrigger = useCallback(
    (spent: number, saved: number) => {
      return notifySuccess("Auto-Saved!", `You spent ${spent} USDC → automatically saved ${saved} USDC`)
    },
    [notifySuccess],
  )

  const notifySpendAndSaveDisabled = useCallback(
    (reason: string) => {
      return notifyWarning(
        "Spend & Save Paused",
        reason || "Your automatic savings have been paused. Enable it to resume.",
      )
    },
    [notifyWarning],
  )

  const notifyInsufficientBalance = useCallback(() => {
    return notifyError(
      "Insufficient Balance",
      "You don't have enough USDC to complete this transaction. Auto-save skipped.",
    )
  }, [notifyError])

  const notifyTargetReached = useCallback(
    (targetName: string) => {
      return notifySuccess("Goal Achieved!", `You've reached your ${targetName} savings goal!`)
    },
    [notifySuccess],
  )

  const notifyFixedUnlocked = useCallback(
    (amount: number) => {
      return notifySuccess("Funds Unlocked", `Your ${amount} USDC are now available to withdraw`)
    },
    [notifySuccess],
  )

  return {
    notifications,
    addNotification,
    removeNotification,
    notifySuccess,
    notifyError,
    notifyInfo,
    notifyWarning,
    notifyDepositSuccess,
    notifyWithdrawSuccess,
    notifySpendAndSaveTrigger,
    notifySpendAndSaveDisabled,
    notifyInsufficientBalance,
    notifyTargetReached,
    notifyFixedUnlocked,
  }
}
