# Update Notes

A few changes I'm wanting to make after testing a little:

---

1. ✅ **DONE** — When adding a profile, the color label is now a Picker dropdown with color swatches instead of a free-text field. Matches the existing Settings screen behavior.

2. ✅ **DONE** — Default machine catalog seeded from the list below. New users (and existing users with no machines) automatically get all 16 machines pre-loaded. Users can still add custom machines at any time.

List:
- Biceps Curl (Arms)
- Leg Press (Platform) (Legs)
- Abdominal Crunch (Core)
- Triceps Press (Arms)
- Leg Extension (Legs)
- Rotary Torso (L) (Core)
- Rotary Torso (R) (Core)
- Lat Pulldown (Machine) (Back)
- Chest Press (Chest)
- Calf Extension (Legs)
- Abdominal (Strap) (Core)
- Lat Pulldown (Cable) (Back)
- Pec Fly (Chest)
- Back Extension (Back)
- Leg Press (Sled) (Legs)
- Cross Body Pull (Back)

3. ✅ **DONE** — The machine picker inside the workout session now has a "+" button in the toolbar to add a new machine without leaving the workout.

4. ✅ **DONE** — The machine picker inside the workout session shows a star icon next to each machine. Tapping it toggles the favorite on/off in real time.

5. ✅ **DONE** — Tapping a weight or reps field for the first time now clears the pre-filled 0, so typing "100" shows "100" not "0100". Subsequent taps on the same field append as before.

6. ✅ **DONE** — "Start Strength Workout" now opens a single session for the day. If a strength session already exists for today it is resumed. Within the session you pick a machine, log sets, tap Done, and return to the session to add more machines. Tapping "Start Strength Workout" again on the same day reopens the same session.

7. ✅ **DONE** — The "Last Workout" card on the home screen is now tappable and navigates into WorkoutDetailView showing all machines and sets.

8. ✅ **DONE** — "Start Cardio Workout" now opens a sheet with the cardio logging flow (manual or HealthKit based on user preference).

9. ✅ **DONE** — History now auto-selects today's date on load, so current-day workouts are visible immediately without having to tap away and back.

10. ✅ **DONE** — History no longer shows duplicate strength entries. Sessions are deduplicated per day (one strength session per day shown). The inline card now shows all machines and their sets directly on the history date view without requiring a tap-through.

11. ✅ **DONE** — Adding a new set now uses the last set's current weight and reps (not the original machine default), so if you changed set 2 to 150 lb, set 3 will pre-fill with 150 lb.


12. ✅ **DONE** — On launch, if profiles exist but none is selected, the app now shows the profile selector screen directly so it's clear what to do. The "Done" button is hidden in this context so the user can't bypass selection.

13. ✅ **DONE** — After creating a new profile, the app immediately presents a "Pick Your Favorites" screen showing all default machines grouped by category. The user can star their preferred machines before entering the app. Those favorites then appear at the top of the machine picker when starting a workout.

14. ✅ **DONE** — Sets are now saved to the SwiftData store immediately as they are added, completed, deleted, or have their weight/reps changed via the number pad. No data is lost if the app is backgrounded mid-session.