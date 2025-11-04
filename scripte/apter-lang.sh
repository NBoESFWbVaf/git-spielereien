#!/bin/bash
clear

# Sprachdefinitionen
declare -A messages_de=(
    ["snapshot_create"]="Erstelle Timeshift-Snapshot: %s"
    ["snapshot_fail"]="Fehler: Timeshift-Snapshot fehlgeschlagen."
    ["timeshift_not_installed"]="Timeshift ist nicht installiert. Überspringe Snapshot."
    ["update_system"]="Aktualisiere Systempakete..."
    ["update_fail"]="Fehler: %s fehlgeschlagen."
    ["flatpak_update"]="Aktualisiere Flatpaks..."
    ["flatpak_not_installed"]="Flatpak ist nicht installiert. Überspringe Flatpak-Aktualisierung."
    ["kernel_remove"]="Suche nach alten Kernels..."
    ["kernel_none"]="Keine alten Kernel zum Entfernen gefunden."
    ["kernel_remove_list"]="Folgende Kernel werden entfernt:"
    ["snap_update"]="Aktualisiere Snaps..."
    ["snap_not_installed"]="Snap ist nicht installiert. Überspringe Snap-Aktualisierung."
    ["clean_files"]="Bereinige temporäre Dateien und Cache..."
    ["clean_logs"]="Behält nur die letzten 50 MB an Logs"
    ["clean_old_logs"]="Alte Logs entfernen"
    ["docker_not_installed"]="Docker ist nicht installiert. Überspringe Docker-Bereinigung."
    ["maintenance_done"]="Systemwartung abgeschlossen."
    ["help_usage"]="Verwendung: $0 [OPTION]"
    ["help_options"]="Optionen:"
    ["help_system"]="  -s, --system      Nur Systempakete aktualisieren"
    ["help_flatpak"]="  -f, --flatpak     Nur Flatpaks aktualisieren und bereinigen"
    ["help_kernel"]="  -k, --kernel      Nur alte Kernel entfernen"
    ["help_snap"]="  -n, --snap        Nur Snaps aktualisieren und bereinigen"
    ["help_clean"]="  -c, --clean       Temporäre Dateien, Logs und Docker bereinigen"
    ["help_all"]="  -a, --all         Alle Aktionen ausführen"
    ["help_help"]="  -h, --help        Diese Hilfe anzeigen"
    ["help_lang"]="  -l, --lang        Sprache wählen (de/en)"
    ["help_combinations"]="Kombinationen ebenfalls möglich. Bsp: apter -s -f"
    ["unknown_option"]="Unbekannte Option: %s"
)

declare -A messages_en=(
    ["snapshot_create"]="Creating Timeshift snapshot: %s"
    ["snapshot_fail"]="Error: Timeshift snapshot failed."
    ["timeshift_not_installed"]="Timeshift is not installed. Skipping snapshot."
    ["update_system"]="Updating system packages..."
    ["update_fail"]="Error: %s failed."
    ["flatpak_update"]="Updating Flatpaks..."
    ["flatpak_not_installed"]="Flatpak is not installed. Skipping Flatpak update."
    ["kernel_remove"]="Searching for old kernels..."
    ["kernel_none"]="No old kernels found to remove."
    ["kernel_remove_list"]="The following kernels will be removed:"
    ["snap_update"]="Updating Snaps..."
    ["snap_not_installed"]="Snap is not installed. Skipping Snap update."
    ["clean_files"]="Cleaning temporary files and cache..."
    ["clean_logs"]="Keeping only the last 50 MB of logs"
    ["clean_old_logs"]="Removing old logs"
    ["docker_not_installed"]="Docker is not installed. Skipping Docker cleanup."
    ["maintenance_done"]="System maintenance completed."
    ["help_usage"]="Usage: $0 [OPTION]"
    ["help_options"]="Options:"
    ["help_system"]="  -s, --system      Update system packages only"
    ["help_flatpak"]="  -f, --flatpak     Update and clean Flatpaks only"
    ["help_kernel"]="  -k, --kernel      Remove old kernels only"
    ["help_snap"]="  -n, --snap        Update and clean Snaps only"
    ["help_clean"]="  -c, --clean       Clean temporary files, logs, and Docker"
    ["help_all"]="  -a, --all         Perform all actions"
    ["help_help"]="  -h, --help        Show this help"
    ["help_lang"]="  -l, --lang        Select language (de/en)"
    ["help_combinations"]="Combinations are also possible. Example: apter -s -f"
    ["unknown_option"]="Unknown option: %s"
)

# Standardsprache
LANG="de"
messages=("${messages_de[@]}")

# Funktion: Sprache laden
load_language() {
    if [[ "$1" == "en" ]]; then
        messages=("${messages_en[@]}")
    else
        messages=("${messages_de[@]}")
    fi
}

# Funktion: Nachricht ausgeben (mit printf für Platzhalter)
msg() {
    local key="$1"
    shift
    printf "${messages[$key]}" "$@"
    echo
}

# Funktion: Timeshift-Snapshot erstellen
create_timeshift_snapshot() {
    local comment="$1"
    if command -v timeshift &> /dev/null; then
        msg "snapshot_create" "$comment"
        sudo timeshift --create --comments "$comment" --tags D --skip-grub
        if [ $? -ne 0 ]; then
            msg "snapshot_fail" >&2
            return 1
        fi
    else
        msg "timeshift_not_installed"
    fi
}

# Hilfe anzeigen
show_help() {
    msg "help_usage"
    msg "help_options"
    msg "help_system"
    msg "help_flatpak"
    msg "help_kernel"
    msg "help_snap"
    msg "help_clean"
    msg "help_all"
    msg "help_help"
    msg "help_lang"
    msg "help_combinations"
    exit 0
}

# Systempakete aktualisieren, upgraden und bereinigen
update_system() {
    if ! create_timeshift_snapshot "Vor Systempaket-Aktualisierung"; then
        return 1
    fi
    msg "update_system"
    if ! sudo apt update; then
        msg "update_fail" "apt update" >&2
        return 1
    fi
    if ! sudo apt upgrade -y; then
        msg "update_fail" "apt upgrade" >&2
        return 1
    fi
    if ! sudo apt full-upgrade -y; then
        msg "update_fail" "apt full-upgrade" >&2
        return 1
    fi
    if ! sudo apt autoremove -y; then
        msg "update_fail" "apt autoremove" >&2
        return 1
    fi
    if ! sudo apt autoclean -y; then
        msg "update_fail" "apt autoclean" >&2
        return 1
    fi
}

# Flatpaks aktualisieren und bereinigen
update_flatpaks() {
    if ! create_timeshift_snapshot "Vor Flatpak-Aktualisierung"; then
        return 1
    fi
    if command -v flatpak &> /dev/null; then
        msg "flatpak_update"
        if ! flatpak update -y; then
            msg "update_fail" "flatpak update" >&2
        fi
        if ! flatpak uninstall --unused --delete-data; then
            msg "update_fail" "flatpak uninstall --unused --delete-data" >&2
        fi
    else
        msg "flatpak_not_installed"
    fi
}

# Alte Kernel entfernen
remove_old_kernels() {
    if ! create_timeshift_snapshot "Vor Kernel-Bereinigung"; then
        return 1
    fi
    msg "kernel_remove"
    current_kernel=$(uname -r | sed "s/\([-0-9]*\)-\([^0-9]\+\)/\1/")
    old_kernels=$(dpkg -l 'linux-[ihs]*' | sed '/^ii/!d;/'"$current_kernel"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d')
    if [ -z "$old_kernels" ]; then
        msg "kernel_none"
        return
    fi
    msg "kernel_remove_list"
    echo "$old_kernels"
    echo "$old_kernels" | xargs sudo apt-get -y purge
}

# Snaps aktualisieren und bereinigen
update_snaps() {
    if ! create_timeshift_snapshot "Vor Snap-Aktualisierung"; then
        return 1
    fi
    if command -v snap &> /dev/null; then
        msg "snap_update"
        if ! sudo snap refresh; then
            msg "update_fail" "snap refresh" >&2
        fi
        if ! sudo snap set system refresh.retain=2; then
            msg "update_fail" "snap set system refresh.retain" >&2
        fi
    else
        msg "snap_not_installed"
    fi
}

# Temporäre Dateien und Cache bereinigen
clean_files() {
    if ! create_timeshift_snapshot "Vor Systembereinigung"; then
        return 1
    fi
    msg "clean_files"
    if ! sudo rm -rf /tmp/* /var/tmp/*; then
        msg "update_fail" "rm -rf /tmp/* /var/tmp/*" >&2
    fi
    msg "clean_logs"
    if ! journalctl --vacuum-size=50M; then
        msg "update_fail" "journalctl --vacuum-size" >&2
    fi
    msg "clean_old_logs"
    if ! sudo find /var/log -type f -name "*.log" -exec truncate -s 0 {} \; 2>/dev/null; then
        msg "update_fail" "find /var/log -type f -name '*.log'" >&2
    fi
    if ! sudo find /var/log -type f -name "*.gz" -delete 2>/dev/null; then
        msg "update_fail" "find /var/log -type f -name '*.gz'" >&2
    fi
    if command -v docker &> /dev/null; then
        msg "Docker-Bereinigung..."
        if ! docker system prune -a; then
            msg "update_fail" "docker system prune" >&2
        fi
    else
        msg "docker_not_installed"
    fi
}

# Hauptprogramm
main() {
    local do_system=false
    local do_flatpak=false
    local do_kernel=false
    local do_snap=false
    local do_clean=false

    # Parameter auswerten
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--system)   do_system=true ;;
            -f|--flatpak)  do_flatpak=true ;;
            -k|--kernel)   do_kernel=true ;;
            -n|--snap)     do_snap=true ;;
            -c|--clean)    do_clean=true ;;
            -a|--all)      do_system=true; do_flatpak=true; do_kernel=true; do_snap=true; do_clean=true ;;
            -h|--help)     show_help ;;
            -l|--lang)     LANG="$2"; load_language "$2"; shift ;;
            *)              msg "unknown_option" "$1"; show_help ;;
        esac
        shift
    done

    # Wenn keine Parameter übergeben wurden, Hilfe anzeigen
    if ! $do_system && ! $do_flatpak && ! $do_kernel && ! $do_snap && ! $do_clean && [[ $# -eq 0 ]]; then
        show_help
    fi

    # Aktionen ausführen
    if $do_system;  then update_system;     fi
    if $do_flatpak; then update_flatpaks;   fi
    if $do_kernel;  then remove_old_kernels; fi
    if $do_snap;    then update_snaps;      fi
    if $do_clean;   then clean_files;        fi

    msg "maintenance_done"
}

# Skript ausführen
main "$@"
