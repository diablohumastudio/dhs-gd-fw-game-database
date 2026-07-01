class_name DataItem extends Resource
## Base "unit of the game database". Every top-level designer-data resource
## (LevelData, AllyData, AchievementData, Collaborator) inherits this. `id` is the
## stable primary key used for database indexing, save keys, and event routing.
## Declared ONLY here — never redeclare `id` in a subclass.

@export var id: StringName
