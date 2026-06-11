#!/usr/bin/env bash
# Check no-regression pytest canonique — copie-moi dans inputs/checks/NN-no-regression.sh
# et remplis les deux TODO.
#
# Pourquoi ce modèle existe (retex ws3, faux-rouge structurel) :
# - `-o addopts=''` neutralise l'addopts scellé dans le pyproject.toml/pytest.ini du
#   repo cible (sinon `-q` + `-q` = `-qq` et la ligne « N passed » disparaît → le
#   check reste rouge même sur du code correct).
# - Le count est parsé proprement, pas grep-é sur un format fragile.
#
# Rappel gate seal : ce check doit être ROUGE sur le workspace vierge. Si le repo
# cible a déjà N tests verts, mets MIN_PASSED strictement au-dessus de N (le travail
# demandé doit AJOUTER de la couverture), ou combine avec une condition propre à la
# tâche (import du nouveau module, présence d'une table, etc.).

REPO_DIR="TODO"   # chemin du repo cible (absolu, ou relatif à la racine du workspace)
MIN_PASSED=TODO   # plancher de tests qui passent (strictement > au count sur vierge)

cd "$REPO_DIR" || exit 1
out="$(pytest -o addopts='' -q 2>&1 | tail -3)"
passed="$(grep -oE '[0-9]+ passed' <<<"$out" | tail -1 | grep -oE '[0-9]+' || true)"
[ -n "$passed" ] && [ "$passed" -ge "$MIN_PASSED" ]
