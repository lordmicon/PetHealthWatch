PetHealthWatch (PHW) - Hunter Utility for Vanilla 1.12.1
-------------------------------------------------------
A smart, context-aware pet management tool that monitors health 
and handles the complexities of pet death and range.

FEATURES:
- Alerts (Visual & Audio) when pet health drops below a threshold.
- Dynamic Button: Switches between Mend Pet, Revive Pet, and Call Pet.
- Smart Range: Changes to "Call Dead Pet" if you are too far from the corpse.
- Persistent Memory: Remembers death even after logout/reload.
- Auto-Rank: Calculates mana cost based on your highest Mend Pet rank.

CONFIGURATION & TOGGLES:
The addon can track your pet using either Percentages (%) or Raw Health points.

1. Switching Modes:
   Type '/phw toggle' to swap between Percent and Raw HP mode. 
   - Percent Mode: Alert triggers when pet is below X% (Default: 50%).
   - Raw HP Mode: Alert triggers when pet is below X health (Default: 500hp).

2. Setting Thresholds:
   Type '/phw set <number>' to change when the alert appears.
   - Example: If in Percent mode, '/phw set 40' triggers at 40%.
   - Example: If in Raw mode, '/phw set 1200' triggers at 1200 HP.

3. Testing:
   Type '/phw test' to force the alert to show/hide to check your UI placement.

4. Troubleshooting:
   If the button is stuck on "Revive" but your pet is alive, type '/phw clear'.
   If the button is lost off-screen, type '/phw reset'.

INSTALLATION:
Place the 'PetHealthWatch' folder into Interface\AddOns\.
Ensure 'PetNeedsHealing.mp3' is in the folder for audio alerts.