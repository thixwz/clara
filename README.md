# CLARA — Clinical Language and Report Analyzer

A local AI medical assistant that analyzes prescriptions, health reports, and explains medications.
## Quick start
1. Clone repo: `git clone https://github.com/thixwz/clara.git`
2. Backend setup:
   - `cd MedAI/ai_backend`
   - `./scripts/setup_llama.sh` (builds llama.cpp locally; models should be placed in `MedAI/ai_backend/models/`)
3. Frontend:
   - `cd clara`
   - `flutter pub get`
   - `flutter run`
## Notes
- `llama.cpp` and model files are intentionally **not** tracked. See `.gitignore`.
- For contributors: use `feat/`, `fix/`, `chore/` conventional commit types.
