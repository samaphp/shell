#/bin/sh
# Install node nvm

#curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# install latest node
nvm install node

# nvm ls-remote
# Install playwright
npm install playwright
# download new browsers for playwright
npx playwright install
