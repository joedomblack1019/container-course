Output ../../assets/generated/week-01-lab-04/demo.gif

Require echo

Set Shell "bash"
Set FontSize 16
Set Width 120
Set Height 50
Set Padding 20
Set TypingSpeed 50ms
Set Theme "Dracula"

Type "# Container Lifecycle Demo 🐳"
Enter
Sleep 1s

Type "echo 'Starting with clean slate...'"
Enter
Type "docker ps -a"
Enter
Sleep 1s

Type "echo"
Enter
Type "# 1. Start a container"
Enter
Type "docker run -d --name demo nginx"
Enter
Sleep 2s

Type "docker ps"
Enter
Sleep 1s

Type "echo"
Enter
Type "# 2. Check container state"
Enter
Type "docker inspect demo --format '{{.State.Status}}'"
Enter
Sleep 1s

Type "echo"
Enter
Type "# 3. Pause the container"
Enter
Type "docker pause demo"
Enter
Sleep 1s
Type "docker ps"
Enter
Sleep 1s

Type "echo"
Enter
Type "# 4. Resume it"
Enter
Type "docker unpause demo"
Enter
Sleep 1s
Type "docker ps"
Enter
Sleep 1s

Type "echo"
Enter
Type "# 5. Execute commands inside"
Enter
Type "docker exec demo hostname"
Enter
Sleep 1s

Type "echo"
Enter
Type "# 6. Stop the container"
Enter
Type "docker stop demo"
Enter
Sleep 2s
Type "docker ps -a"
Enter
Sleep 1s

Type "echo"
Enter
Type "# 7. Start it again"
Enter
Type "docker start demo"
Enter
Sleep 1s
Type "docker ps"
Enter
Sleep 1s

Type "echo"
Enter
Type "# 8. Create data inside"
Enter
Type "docker exec demo touch /tmp/myfile.txt"
Enter
Sleep 1s
Type "docker exec demo ls /tmp/"
Enter
Sleep 1s

Type "echo"
Enter
Type "# 9. Stop and start again - data persists"
Enter
Type "docker stop demo && docker start demo"
Enter
Sleep 2s
Type "docker exec demo ls /tmp/"
Enter
Sleep 1s

Type "echo"
Enter
Type "# 10. Remove container - data is lost!"
Enter
Type "docker rm -f demo"
Enter
Sleep 1s
Type "docker run -d --name demo2 nginx"
Enter
Sleep 1s
Type "docker exec demo2 ls /tmp/"
Enter
Sleep 1s

Type "echo"
Enter
Type "# Clean up"
Enter
Type "docker rm -f demo2"
Enter
Sleep 1s

Type "echo"
Enter
Type "echo '✅ Key Concepts Demonstrated:'"
Enter
Type "echo '  • Container states: running → paused → stopped'"
Enter
Type "echo '  • Data persists through stop/start'"
Enter
Type "echo '  • Data is lost when container is removed'"
Enter
Type "echo '  • Images vs containers distinction'"
Enter
Sleep 2s