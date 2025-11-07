# CreateRailNet-V2

### 🚂 Vollautomatisches Zug- und Cargo-Netzwerk für Create & ComputerCraft

![Version](https://img.shields.io/badge/version-1.0-blue)
![Minecraft](https://img.shields.io/badge/Minecraft-1.21.x-green)
![License](https://img.shields.io/badge/license-MIT-lightgrey)
![Status](https://img.shields.io/badge/status-stable-brightgreen)

---

## 🧩 Überblick

**CreateRailNet** ist ein modulares Lua-Framework für **ComputerCraft / CC: Tweaked**,  
das ein vollständiges, automatisiertes Bahn- und Logistiksystem in Minecraft ermöglicht.  

Es integriert **Create-Züge**, **Depots**, **Stationen** und **Cargo-Verwaltung**  
zu einem dezentralen Netzwerk mit GUI, Signallogik und Selbstregelung.

---

## 🚀 Features

### 📦 Cargo-System
- Automatisierte Frachtsteuerung mit Lade- & Entladepunkten  
- Dynamisches Routing mit Warteschlange und Prioritäten  
- Fortschritts- und Statusanzeigen im GUI  

### 🏭 Depot-Management
- Verwaltung mehrerer Depots und Zugtypen  
- Automatisches Dispatching und Service-Logik  
- Selbstheilung bei Timeout oder Job-Fehlern  

### 🚂 Create-Integration
- Kompatibel mit **Create Trains**  
- Steuerung über Peripheral oder Redstone  
- Unterstützung für Signale, Weichen, Boost & Stop  

### 🖥️ GUI & Bedienung
- Multi-Tab-Interface mit Touch- und Tastatursteuerung  
- Tabs: **Dashboard**, **Depot**, **Cargo**, **TrainControl**  
- Echtzeitdaten über den internen Transport-Bus  

### ⚙️ Konfiguration
- JSON-basierte Settings & Policies  
- Anpassbare Farben, Service-Logik und Route-Definitionen  
- Modularer Aufbau → eigene Module leicht integrierbar  

---

## 📁 Projektstruktur


---

## 🧠 Voraussetzungen

- **Minecraft 1.21.x**
- **Modpack:** All The Mods 10 (oder kompatibel)
- **Benötigte Mods:**
  - [Create](https://www.curseforge.com/minecraft/mc-mods/create)
  - [ComputerCraft: Tweaked](https://www.curseforge.com/minecraft/mc-mods/cc-tweaked)
- **Optional:**
  - Mekanism (für Energie & Fluidintegration)
  - Railcraft (Signal- & Streckenlogik)

---

## 🧩 Installation

1. Lade das aktuelle Release herunter:  
   👉 [CreateRailNet-main-v1.0-Full.zip](./CreateRailNet-main-v1.0-Full.zip)

2. Entpacke die Dateien in den Root-Ordner deines **ComputerCraft-Computers**.

3. (Optional) Installer starten:
   ```lua
   shell.run("install.lua")
