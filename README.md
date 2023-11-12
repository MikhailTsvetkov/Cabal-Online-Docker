# CabalDocker
This Cabal Online server management system is based on Docker containers.
Docker container is a virtualization system, which allows you to "pack" the application
with all its environment and dependencies into a container.
It's like a virtual machine that does NOT reserve system resources.
That is, the container will not consume resources other than those needed directly by the Cabal server.
At the same time, we have the opportunity to run several completely isolated
Cabal servers and databases for them on one VPS/VDS.
This can be useful if you have multiple Cabal servers or want to run additional server for tests.
In this case, they will have the same IP address and different ports.
Naturally, MSSQL no longer needs Windows. The databases will also run in containers on the main server.
