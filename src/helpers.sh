#!/bin/bash

source "${SCRIPT_DIR}/spinner.sh"
source "${SCRIPT_DIR}/bash-init.sh"

# Function to check if a package is installed
__is_package_installed() {
    local package_name="$1"
    if dpkg-query --show --showformat='${db:Status-Status}' $package_name 2>&1 | grep -q "installed"; then
        return 0 # Package is installed
    else
        return 1 # Package is not installed
    fi
    #if dpkg-query -W --showformat='${Status}\n' "${package_name}" | grep "install ok installed" &> /dev/null; then
    #    return 0 # Package is installed
    #else
    #    return 1 # Package is not installed
    #fi
}

install_packages() {
    local packages_list=("$@")

    for pkg in "${packages_list[@]}"; do
        if ! __is_package_installed "$pkg"; then
            printf "${YELLOW}${BOLD}Installing: $pkg${NC}\n"
            apt install -y "$pkg" &
            spinner $!
        fi
    done    
}

install_packages_silent() {
    local packages_list=("$@")

    for pkg in "${packages_list[@]}"; do
        if ! __is_package_installed "$pkg"; then
            printf "${YELLOW}${BOLD}Installing: $pkg${NC}\n"
            (
                apt install "$pkg" -y -qq > /dev/null 2>&1
            ) &
            INSTALL_PID=$!
            spinner $INSTALL_PID
        fi
    done    
}

# run_step - execute a command and wrap its output in a titled section
#
# Usage:
#   run_step [<title> --] <command> [args...]
#   run_step [<title>] @@ <raw-shell-string>
#
# If <title> is omitted, the full command line (or raw string) becomes the title.
#
# Modes:
#   --  safe: each argument is shell-escaped
#   @@  raw: eval the entire string (pipes, redirects, etc.)
#
# On GitHub Actions (GITHUB_ACTIONS=true):
#   ::group::<title>
#     ...traced output..
#   ::endgroup::
#
# Otherwise: prints box delimiters
run_step() {
  local -a args
  args=("$@")

  # Need at least one argument
  (( ${#args[@]} )) || {
    log ERROR "Usage: run_step [<title> --] <cmd> [args...] | [<title>] @@ <raw-shell-string>"
    return 2
  }

  local cmd title
  if [[ ${args[0]} == '@@' ]]; then
    (( ${#args[@]} > 1 )) || {
      log ERROR "Usage: run_step @@ <raw-shell-string>"
      return 2
    }
    cmd=${args[1]}
    title=$cmd
  elif (( ${#args[@]} > 1 )) && [[ ${args[1]} == '@@' ]]; then
   (( ${#args[@]} > 2 )) || {
     log ERROR "Usage: run_step <title> @@ <raw-shell-string>"
     return 2
   }
    title=${args[0]}
    cmd=${args[2]}
  else
    # Parse title and cmd
    local -a cmd_parts
    cmd_parts=()
    if [[ ${args[0]} == -- ]]; then
      title="${args[*]:1}"
      cmd_parts=( "${args[@]:1}" )
    elif (( ${#args[@]} > 1 )) && [[ ${args[1]} == -- ]]; then
      title=${args[0]}
      cmd_parts=( "${args[@]:2}" )
    else
      cmd_parts=( "${args[@]}" )
      title=${args[*]}
    fi

    # Must have a command to run
    (( ${#cmd_parts[@]} )) || {
      log ERROR "Usage: run_step [<title> --] <cmd> [args...] | [<title>] @@ <raw-shell-string>"
      return 2
    }

    # Build the eval-safe command string
    local part
    for part in "${cmd_parts[@]}"; do
      cmd+=" $(printf '%q' "$part")"
    done
    cmd=${cmd# }  # strip the leading space
  fi

  # Header
  info_box "$title"
  set -e

  # Create a temporary file to capture command output (stdout and stderr)
  local temp_error
  temp_error=$(mktemp)
  
  printf '\033[90m+ %s:%d:\033[0;1m %s\033[0m\n'  "${BASH_SOURCE[1]}" "${BASH_LINENO[0]}" "$cmd"

  # Execute command with tracing and spinner
  local rc
  set +e

  local temp_out temp_error temp_rc
  temp_out=$(mktemp)
  temp_error=$(mktemp)
  temp_rc=$(mktemp)

  script --flush --quiet --command "bash -c '$cmd; echo \$? > $temp_rc'" /dev/null >"$temp_out" 2>"$temp_error" &
  CMD_PID=$!

  tput civis
  local spin=('⣾' '⣽' '⣻' '⢿' '⡿' '⣟' '⣯' '⣷')
  local i=0
  while kill -0 $CMD_PID 2>/dev/null; do
      if [[ -s $temp_out ]]; then
          cat "$temp_out" >/dev/tty
          : > "$temp_out"
          sleep 0.05
      else
          printf "%s" "${spin[$i]}"
          i=$(((i + 1) % ${#spin[@]}))
          echo -en "\033[1D"
          sleep 0.1
      fi
  done
  tput cnorm

  # Flush remaining output
  [[ -s $temp_out ]] && cat "$temp_out" >/dev/tty

  # Read the exit code from the temp file
  if [[ -f $temp_rc ]]; then
    rc=$(<"$temp_rc")
  else
    rc=12  # fallback if something went wrong
  fi

  set -e  # restore fail-fast behavior
  # Footer
  if [ $rc -eq 0 ]; then
    success_box "$title"
  else
    error_box "$title"
    #printf "${RED}------ stderr ------${NC}\n" >&2
    #cat "$temp_error"
    #printf "${RED}--------------------${NC}\n" >&2
  fi

  # Clean up the temporary file
  rm -f "$temp_error" "$temp_out" "$temp_rc"

  return $rc
}

# start_docker_registry - Launch a local Docker registry and export its address
#
# Usage:
#   start_docker_registry <ENV_VAR_NAME>
#
# Description:
#   Starts a Docker registry container with automatic host-port mapping.
#   Waits for the registry at `http://127.0.0.1:<port>/v2/` to become ready,
#   then exports:
#     <ENV_VAR_NAME>               – registry endpoint (host:port, e.g. 127.0.0.1:32768)
#     <ENV_VAR_NAME>_CONTAINER_ID  – container ID
#     <ENV_VAR_NAME>_CONTAINER_NAME– container name
#   Registers a trap to stop the registry on script EXIT.
#
# Example:
#   start_docker_registry LOCAL_REGISTRY
#   curl http://$LOCAL_REGISTRY/v2/
function start_docker_registry() {
  local result_env_var=$1

  # Detect whether *this* script is running in a container
  if ! grep -Eq '(docker|kubepods|containerd|actions_job)' <(head -n1 /proc/1/cgroup); then
    local run_args="-P" # we’re on a host VM -> publish random host port
  fi

  # Launch the registry with an automatic host port
  local container_id
  # shellcheck disable=SC2086  # Double quote to prevent globbing and word
  container_id=$(docker run -d --rm ${run_args:-} ghcr.io/dockerhub-mirror/registry)
  if [[ -z $container_id ]]; then
    echo "❌ Failed to start registry container" >&2
    return 1
  fi
  add_trap "docker stop '$container_id'" EXIT

  local host port
  if [[ -z ${run_args:-} ]]; then
    # --- inside a container (e.g. act_runner): use container IP + fixed port 5000
    host=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_id")
    port=5000
  else
    # --- outside: discover the random host port that Docker published
    for _ in {1..10}; do
      port=$(docker inspect --format='{{ (index (index .NetworkSettings.Ports "5000/tcp") 0).HostPort }}' "$container_id")
      [[ -n $port ]] && break
      sleep 0.2
    done
    if [[ -z $port ]]; then
      echo "❌ Could not determine host port for registry" >&2
      docker stop "$container_id"
      return 1
    fi
    host=127.0.0.1
  fi

  # Wait for the registry to become reachable
  local local_registry="$host:$port"
  local local_registry_url="http://$local_registry/v2/"
  log INFO "Waiting for Docker registry [$local_registry_url] to be ready..."
  if ! curl_with_retry \
            --max-time 1 \
            --retry 10 \
            --retry-delay 1 \
            --retry-max-time 10 \
            "$local_registry_url"; then
    echo "❌ Docker registry failed to start" >&2
    docker stop "$container_id"
    return 1
  fi
  log INFO "✅ Registry is ready."

  # Export variables
  export "$result_env_var"="$local_registry"
  echo "$result_env_var=$local_registry"

  export "${result_env_var}_CONTAINER_ID"="$container_id"
  echo "${result_env_var}_CONTAINER_ID=$container_id"

  local container_name
  container_name=$(docker inspect --format='{{.Name}}' "$container_id" | sed 's|^/||')
  export "${result_env_var}_CONTAINER_NAME"="$container_name"
  echo "${result_env_var}_CONTAINER_NAME=$container_name"
}
