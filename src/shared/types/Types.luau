-- Types partagés RootEmpire

export type ZoneId = "forest" | "mine" | "farm" | "coastal" | "volcanic"

export type ResourceId =
    -- Forest
    "raw_wood" | "plank" | "furniture" |
    -- Mine
    "stone" | "ore" | "ingot" | "tool" |
    -- Farm
    "wheat" | "flour" | "bread" |
    -- Coastal
    "raw_fish" | "canned_fish" |
    -- Volcanic
    "magma_rock" | "refined_crystal"

export type MachineId =
    -- Forest
    "sawmill" | "planer" | "workshop" |
    -- Mine
    "drill" | "furnace" | "forge" |
    -- Farm
    "mill" | "oven" | "silo" |
    -- Coastal
    "fishing_boat" | "cannery" |
    -- Volcanic
    "lava_extractor" | "crystal_refiner"

export type Machine = {
    id: MachineId,
    displayName: string,
    input: ResourceId,
    output: ResourceId,
    productionTime: number, -- secondes
    outputAmount: number,   -- quantité produite par cycle
    cost: number,
    zone: ZoneId,
}

export type Zone = {
    id: ZoneId,
    displayName: string,
    unlockCost: number,
    requiredRebirths: number,
    machines: { MachineId },
}

export type MachineState = {
    id: MachineId,
    isRunning: boolean,
    progress: number,   -- 0 à 1
    inputStock: number,
    outputStock: number,
}

export type PlayerData = {
    coins: number,
    rebirths: number,
    multiplier: number,
    resources: { [ResourceId]: number },  -- ← ajout
    unlockedZones: { ZoneId },
    ownedMachines: { [MachineId]: MachineState },
    stats: {
        totalProduced: number,
        totalEarned: number,
        playTime: number,
    },
}

export type RemotePayload<T> = {
    success: boolean,
    data: T?,
    error: string?,
}

return {}