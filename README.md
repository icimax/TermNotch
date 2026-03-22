add to your ~/.bashrc
```
precmd() {
    local exit_status=$?

    if [[ $zsh_command_start_time -gt 0 ]]; then
        local current_time=$(date +%s)
        local elapsed=$((current_time - zsh_command_start_time))
        zsh_command_start_time=0

        # 1. On ne notifie que si la tâche a pris plus de 5 secondes
        if [[ $elapsed -gt 5 ]]; then

            # 2. BONUS INTELLIGENT : On vérifie l'application actuellement active
            local active_app=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true')

            # Si le terminal N'EST PAS l'application au premier plan (tu as vaqué à tes occupations)
            # (Note : Modifie "iTerm2" si tu utilises un autre terminal comme Ghostty ou WezTerm)
            if [[ "$active_app" != "Terminal" && "$active_app" != "iTerm2" ]]; then

                # Formatage du message avec le statut
                local msg="✅ Terminé (${elapsed}s)"
                if [[ $exit_status -ne 0 ]]; then
                    msg="❌ Erreur (${elapsed}s)"
                fi

                # 3. Lancement de notre utilitaire en tâche de fond (&!)
                # Remplace le chemin si tu l'as sauvegardé ailleurs
            open -a ~/Applications/TermNotch.app --args "$msg"

            fi
        fi
    fi
}
```

then run 
```
./build.sh
```