FROM ubuntu:22.04

RUN apt update -y && apt upgrade -y && apt install curl git jq libicu70 -y

#Install dotnet runtime
RUN apt-get update && apt-get install -y dotnet-runtime-8.0

# Install the ASP.NET Core Runtime (for running apps)
RUN apt-get update && apt-get install -y aspnetcore-runtime-8.0

RUN export DOTNET_ROOT=$HOME/.dotnet
RUN export PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools

# Also can be "linux-arm", "linux-arm64"
ENV TARGETARCH="linux-x64"

WORKDIR /azp/

COPY ./start.sh ./
RUN chmod +x ./start.sh

# Create agent user and set up home directory
RUN useradd -m -d /home/agent agent
RUN chown -R agent:agent /azp /home/agent

USER agent
# Another option is to run the agent as root.
# ENV AGENT_ALLOW_RUNASROOT="true"

ENTRYPOINT [ "./start.sh" ]