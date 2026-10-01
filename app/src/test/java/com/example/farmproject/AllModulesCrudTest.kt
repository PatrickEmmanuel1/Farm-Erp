package com.example.farmproject

import com.example.farmproject.data.model.CreateEmployeeRequest
import com.example.farmproject.data.model.Crop
import com.example.farmproject.data.model.CropPlanting
import com.example.farmproject.data.model.CropPlantingDisplay
import com.example.farmproject.data.model.Division
import com.example.farmproject.data.model.EmployeeDisplay
import com.example.farmproject.data.model.Fertilizer
import com.example.farmproject.data.model.InventoryCategory
import com.example.farmproject.data.model.Machinery
import com.example.farmproject.data.model.MachineryMaintenance
import com.example.farmproject.data.model.MachineryUsage
import com.example.farmproject.data.model.Pesticide
import com.example.farmproject.data.model.StockIssuance
import com.example.farmproject.data.model.Water
import com.example.farmproject.data.model.toInventoryItem
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class AllModulesCrudTest {

    // ---------------------------------------------------------------------
    // 1. CROP MODULE CRUD TESTS
    // ---------------------------------------------------------------------

    @Test
    fun testCropAndPlantingCrud() {
        // CREATE
        val crop = Crop(
            cropId = "crop-maize-1",
            name = "Maize",
            scientificName = "Zea mays",
            description = "White hybrid maize"
        )
        assertEquals("Maize", crop.name)
        assertEquals("Zea mays", crop.scientificName)

        val plantings = mutableListOf(
            CropPlanting(
                plantingId = "p-1",
                cropId = "crop-maize-1",
                farmId = "f-1",
                divisionId = "div-north",
                plantingDate = "2026-03-15",
                areaPlanted = 5.0,
                areaUnit = "Acres",
                plantingStatus = "Active"
            ),
            CropPlanting(
                plantingId = "p-2",
                cropId = "crop-maize-1",
                farmId = "f-1",
                divisionId = "div-south",
                plantingDate = "2026-02-10",
                areaPlanted = 3.0,
                areaUnit = "Acres",
                plantingStatus = "Harvested"
            )
        )

        // READ / FILTER
        val activePlantings = plantings.filter { it.plantingStatus.equals("Active", ignoreCase = true) && !it.isDeleted }
        assertEquals(1, activePlantings.size)
        assertEquals("p-1", activePlantings.first().plantingId)

        // DISPLAY MAPPING
        val display = CropPlantingDisplay(
            planting = activePlantings.first(),
            cropName = crop.name,
            divisionName = "North Division"
        )
        assertEquals("Maize", display.cropName)
        assertEquals("North Division", display.divisionName)

        // UPDATE
        val updateIndex = plantings.indexOfFirst { it.plantingId == "p-1" }
        plantings[updateIndex] = plantings[updateIndex].copy(
            notes = "Fertilizer applied on 2026-03-20",
            plantingStatus = "Growing"
        )
        assertEquals("Fertilizer applied on 2026-03-20", plantings[updateIndex].notes)

        // DELETE
        plantings.removeAll { it.plantingId == "p-2" }
        assertEquals(1, plantings.size)
        assertNull(plantings.find { it.plantingId == "p-2" })
    }

    // ---------------------------------------------------------------------
    // 2. INVENTORY MODULE CRUD TESTS
    // ---------------------------------------------------------------------

    @Test
    fun testInventoryCrudAndStockLogic() {
        // CREATE & MODEL CONVERSION
        val fertilizer = Fertilizer(
            fertilizerId = "fert-1",
            farmId = "f-1",
            name = "DAP 18-46-0",
            fertilizerType = "Inorganic",
            quantity = 10.0,
            unit = "Bags",
            reorderLevel = 15.0,
            description = "Planting fertilizer"
        )
        val fertItem = fertilizer.toInventoryItem()
        assertEquals(InventoryCategory.FERTILIZER, fertItem.category)
        assertEquals("DAP 18-46-0", fertItem.name)
        assertTrue("Expected low stock when quantity (10) <= reorder (15)", fertItem.isLowStock)

        val pesticide = Pesticide(
            pesticideId = "pest-1",
            farmId = "f-1",
            name = "Belt Expert",
            activeIngredient = "Flubendiamide",
            quantity = 50.0,
            unit = "Litres",
            reorderLevel = 10.0,
            description = "Insect pest control"
        )
        val pestItem = pesticide.toInventoryItem()
        assertFalse("Expected normal stock when quantity (50) > reorder (10)", pestItem.isLowStock)

        val water = Water(
            waterId = "wat-1",
            farmId = "f-1",
            sourceName = "Borehole 1",
            availableQuantity = 1000.0,
            unit = "Litres",
            reorderLevel = 200.0
        )
        val waterItem = water.toInventoryItem()
        assertEquals("Borehole 1", waterItem.name)

        // READ & FILTER LIST
        val inventoryList = mutableListOf(fertItem, pestItem, waterItem)
        val lowStockItems = inventoryList.filter { it.isLowStock }
        assertEquals(1, lowStockItems.size)
        assertEquals("DAP 18-46-0", lowStockItems.first().name)

        // UPDATE (Restock Fertilizer)
        val index = inventoryList.indexOfFirst { it.id == "fert-1" }
        val restockedFert = inventoryList[index].copy(quantity = 50.0)
        inventoryList[index] = restockedFert
        assertFalse("Restocked item should no longer be low stock", inventoryList[index].isLowStock)

        // STOCK ISSUANCE
        val issuance = StockIssuance(
            issuanceId = "iss-1",
            itemId = "pest-1",
            category = "Pesticide",
            itemName = "Belt Expert",
            quantityIssued = 5.0,
            unit = "Litres",
            issuedTo = "John Worker",
            issueDate = "2026-03-30",
            notes = "Issued for maize spraying",
            farmId = "f-1"
        )
        assertEquals(5.0, issuance.safeQuantityIssued, 0.001)

        // DELETE
        inventoryList.removeAll { it.id == "wat-1" }
        assertEquals(2, inventoryList.size)
        assertNull(inventoryList.find { it.id == "wat-1" })
    }

    // ---------------------------------------------------------------------
    // 3. MACHINERY MODULE CRUD TESTS
    // ---------------------------------------------------------------------

    @Test
    fun testMachineryUsageAndMaintenanceCrud() {
        // CREATE
        val machineryList = mutableListOf(
            Machinery(
                machineryId = "mach-1",
                farmId = "f-1",
                name = "Massey Ferguson 375",
                machineryType = "Tractor",
                condition = "Good",
                status = "Available",
                location = "Main Shed"
            ),
            Machinery(
                machineryId = "mach-2",
                farmId = "f-1",
                name = "Boom Sprayer 600L",
                machineryType = "Sprayer",
                condition = "Needs Service",
                status = "Maintenance",
                location = "Field B"
            )
        )

        // READ / STATUS FILTER
        val available = machineryList.filter { it.status.equals("Available", ignoreCase = true) }
        val maintenance = machineryList.filter { it.status.equals("Maintenance", ignoreCase = true) }
        assertEquals(1, available.size)
        assertEquals(1, maintenance.size)

        // USAGE LOGGING
        val usages = mutableListOf(
            MachineryUsage(
                usageId = "u-1",
                machineryId = "mach-1",
                farmId = "f-1",
                usageDate = "2026-03-25",
                hoursUsed = 4.5,
                purpose = "Plowing Division 1",
                fuelUsed = 18.0
            ),
            MachineryUsage(
                usageId = "u-2",
                machineryId = "mach-1",
                farmId = "f-1",
                usageDate = "2026-03-28",
                hoursUsed = 3.0,
                purpose = "Harrowing Division 1",
                fuelUsed = 12.0
            )
        )

        val totalHoursForMach1 = usages.filter { it.machineryId == "mach-1" }.sumOf { it.hoursUsed ?: 0.0 }
        val totalFuelForMach1 = usages.filter { it.machineryId == "mach-1" }.sumOf { it.fuelUsed ?: 0.0 }
        assertEquals(7.5, totalHoursForMach1, 0.001)
        assertEquals(30.0, totalFuelForMach1, 0.001)

        // MAINTENANCE RECORDING
        val maintenanceLogs = listOf(
            MachineryMaintenance(
                maintenanceId = "m-1",
                machineryId = "mach-2",
                farmId = "f-1",
                maintenanceDate = "2026-03-20",
                maintenanceType = "Oil Change & Filter Replacement",
                description = "Replaced engine oil and fuel filters",
                cost = 150.0,
                nextMaintenanceDate = "2026-06-20"
            )
        )
        assertEquals(150.0, maintenanceLogs.first().cost ?: 0.0, 0.001)

        // UPDATE STATUS
        val updateIdx = machineryList.indexOfFirst { it.machineryId == "mach-2" }
        machineryList[updateIdx] = machineryList[updateIdx].copy(status = "Available", condition = "Excellent")
        assertEquals("Available", machineryList[updateIdx].status)

        // DELETE
        machineryList.removeAll { it.machineryId == "mach-2" }
        assertEquals(1, machineryList.size)
    }

    // ---------------------------------------------------------------------
    // 4. EMPLOYEE MODULE CRUD TESTS
    // ---------------------------------------------------------------------

    @Test
    fun testEmployeeCrudAndRoles() {
        // CREATE REQUEST VALIDATION
        val createSupervisor = CreateEmployeeRequest(
            fullName = "Alice Wanjiku",
            email = "alice@farm.com",
            phoneNumber = "+254712345678",
            employeeNumber = "SUP001",
            password = "securePassword123",
            farmId = "f-1"
        )
        assertEquals("Alice Wanjiku", createSupervisor.fullName)
        assertEquals("SUP001", createSupervisor.employeeNumber)

        val createWorker = CreateEmployeeRequest(
            fullName = "Bob Omari",
            email = "bob@farm.com",
            phoneNumber = "+254722998877",
            employeeNumber = "WRK010",
            password = "securePassword123",
            farmId = "f-1"
        )
        assertEquals("Bob Omari", createWorker.fullName)

        // READ & DISPLAY LIST
        val employees = mutableListOf(
            EmployeeDisplay(
                profileId = "prof-sup-1",
                accountId = "acc-1",
                fullName = "Alice Wanjiku",
                email = "alice@farm.com",
                phoneNumber = "+254712345678",
                employeeNumber = "SUP001"
            ),
            EmployeeDisplay(
                profileId = "prof-wrk-1",
                accountId = "acc-2",
                fullName = "Bob Omari",
                email = "bob@farm.com",
                phoneNumber = "+254722998877",
                employeeNumber = "WRK010"
            )
        )

        assertEquals(2, employees.size)

        // UPDATE EMPLOYEE
        val workerIdx = employees.indexOfFirst { it.profileId == "prof-wrk-1" }
        employees[workerIdx] = employees[workerIdx].copy(
            phoneNumber = "+254700000000",
            employeeNumber = "WRK010-UPDATED"
        )
        assertEquals("+254700000000", employees[workerIdx].phoneNumber)
        assertEquals("WRK010-UPDATED", employees[workerIdx].employeeNumber)

        // DELETE WORKER
        employees.removeAll { it.profileId == "prof-wrk-1" }
        assertEquals(1, employees.size)
        assertNull(employees.find { it.profileId == "prof-wrk-1" })
    }

    // ---------------------------------------------------------------------
    // 5. DIVISION MODULE CRUD TESTS
    // ---------------------------------------------------------------------

    @Test
    fun testDivisionCrud() {
        // CREATE
        val divisions = mutableListOf(
            Division(
                divisionId = "div-1",
                farmId = "f-1",
                name = "North Field",
                size = 12.5,
                units = "Acres",
                soilPh = 6.5,
                soilHealth = "Good"
            ),
            Division(
                divisionId = "div-2",
                farmId = "f-1",
                name = "South Field",
                size = 8.0,
                units = "Acres",
                soilPh = 5.8,
                soilHealth = "Fair"
            )
        )

        // READ
        val activeDivisions = divisions.filter { !it.isDeleted }
        assertEquals(2, activeDivisions.size)

        // UPDATE
        val divIndex = divisions.indexOfFirst { it.divisionId == "div-2" }
        divisions[divIndex] = divisions[divIndex].copy(
            soilPh = 6.2,
            soilHealth = "Improved"
        )
        assertEquals(6.2, divisions[divIndex].soilPh!!, 0.001)

        // DELETE (Soft Delete / Remove)
        divisions[divIndex] = divisions[divIndex].copy(isDeleted = true)
        val remaining = divisions.filter { !it.isDeleted }
        assertEquals(1, remaining.size)
        assertEquals("North Field", remaining.first().name)
    }
}
