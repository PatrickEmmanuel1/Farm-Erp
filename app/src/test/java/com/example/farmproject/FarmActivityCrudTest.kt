package com.example.farmproject

import com.example.farmproject.data.model.FarmActivity
import com.example.farmproject.data.model.FarmActivityDisplay
import com.example.farmproject.data.model.InventoryCategory
import com.example.farmproject.data.model.Machinery
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.UUID

class FarmActivityCrudTest {

    @Test
    fun testCreateFarmActivity() {
        val id = UUID.randomUUID().toString()
        val farmId = "farm-123"
        val typeId = "type-planting"
        val date = "2026-03-30"
        val roleMethod = "Role: Worker"
        val notes = "Planting maize in Division A"

        val activity = FarmActivity(
            activityId = id,
            activityTypeId = typeId,
            farmId = farmId,
            divisionId = "div-1",
            activityDate = date,
            status = "pending",
            method = roleMethod,
            notes = notes
        )

        assertEquals(id, activity.activityId)
        assertEquals(farmId, activity.farmId)
        assertEquals("div-1", activity.divisionId)
        assertEquals("pending", activity.status)
        assertEquals("Role: Worker", activity.method)
        assertEquals(notes, activity.notes)
    }

    @Test
    fun testFarmActivityDisplayMapping() {
        val activity = FarmActivity(
            activityId = "act-1",
            activityTypeId = "type-1",
            farmId = "farm-1",
            divisionId = "div-1",
            activityDate = "2026-03-30",
            status = "pending",
            method = "Role: Supervisor",
            notes = "Test notes"
        )

        val displayWithDivision = FarmActivityDisplay(
            activity = activity,
            activityTypeName = "Planting",
            divisionName = "North Field",
            assignedToName = "Supervisor"
        )

        assertEquals("Planting (North Field)", displayWithDivision.displayTitle)
        assertEquals("Planting", displayWithDivision.activityTypeName)
        assertEquals("Supervisor", displayWithDivision.assignedToName)

        val displayNoDivision = FarmActivityDisplay(
            activity = activity.copy(divisionId = null),
            activityTypeName = "Irrigation",
            divisionName = null,
            assignedToName = null
        )

        assertEquals("Irrigation", displayNoDivision.displayTitle)
        assertNull(displayNoDivision.divisionName)
        assertNull(displayNoDivision.assignedToName)
    }

    @Test
    fun testActivityStatusTransitions() {
        val activities = mutableListOf(
            FarmActivity(
                activityId = "act-1",
                activityTypeId = "type-1",
                farmId = "farm-1",
                activityDate = "2026-03-30",
                status = "pending"
            ),
            FarmActivity(
                activityId = "act-2",
                activityTypeId = "type-2",
                farmId = "farm-1",
                activityDate = "2026-03-30",
                status = "in_progress"
            )
        )

        // 1. Verify pending filter
        val pendingList = activities.filter { it.status.equals("pending", ignoreCase = true) }
        assertEquals(1, pendingList.size)
        assertEquals("act-1", pendingList.first().activityId)

        // 2. Begin Activity (Transition act-1 to in_progress)
        val index = activities.indexOfFirst { it.activityId == "act-1" }
        activities[index] = activities[index].copy(status = "in_progress")

        val inProgressList = activities.filter {
            it.status.equals("in_progress", ignoreCase = true) || it.status.equals("In Progress", ignoreCase = true)
        }
        assertEquals(2, inProgressList.size)

        // 3. Complete Activity (Transition act-1 to completed)
        activities[index] = activities[index].copy(status = "completed")

        val completedList = activities.filter {
            it.status.equals("completed", ignoreCase = true) || it.status.equals("Completed", ignoreCase = true)
        }
        assertEquals(1, completedList.size)
        assertEquals("act-1", completedList.first().activityId)
    }

    @Test
    fun testDeleteActivity() {
        val activities = mutableListOf(
            FarmActivity(activityId = "act-1", activityTypeId = "t1", farmId = "f1", activityDate = "2026-03-30", status = "pending"),
            FarmActivity(activityId = "act-2", activityTypeId = "t2", farmId = "f1", activityDate = "2026-03-30", status = "completed")
        )

        assertEquals(2, activities.size)

        // Delete act-1
        activities.removeAll { it.activityId == "act-1" }

        assertEquals(1, activities.size)
        assertNull(activities.find { it.activityId == "act-1" })
        assertNotNull(activities.find { it.activityId == "act-2" })
    }

    @Test
    fun testMachineryStatusFiltering() {
        val machines = listOf(
            Machinery(machineryId = "m1", farmId = "f1", name = "Tractor 1", machineryType = "Tractor", status = "Available", condition = "Good"),
            Machinery(machineryId = "m2", farmId = "f1", name = "Tractor 2", machineryType = "Tractor", status = "Maintenance", condition = "Needs Service")
        )

        val available = machines.filter { it.status.equals("Available", ignoreCase = true) }
        val maintenance = machines.filter { it.status.equals("Maintenance", ignoreCase = true) }

        assertEquals(1, available.size)
        assertEquals("Tractor 1", available.first().name)

        assertEquals(1, maintenance.size)
        assertEquals("Tractor 2", maintenance.first().name)
    }

    @Test
    fun testInventoryCategoryEnum() {
        assertEquals("Fertilizer", InventoryCategory.FERTILIZER.displayName)
        assertEquals("Herbicide", InventoryCategory.HERBICIDE.displayName)
        assertEquals("Pesticide", InventoryCategory.PESTICIDE.displayName)
        assertEquals("Fungicide", InventoryCategory.FUNGICIDE.displayName)
        assertEquals("Insecticide", InventoryCategory.INSECTICIDE.displayName)
        assertEquals("Water", InventoryCategory.WATER.displayName)
    }
}
