#/bin/sh
# Install jMeter

wget https://dlcdn.apache.org/jmeter/binaries/apache-jmeter-5.6.3.tgz
tar xvf apache-jmeter-5.6.3.tgz
sudo mv apache-jmeter-5.6.3 /opt/apache-jmeter

#/opt/apache-jmeter/bin/jmeter.sh -dlog_level=debug

#java -version
#readlink -f $(which java)

# Troubleshooting
# - When trying to run jmeter getting error:
# -- /opt/apache-jmeter/bin/jmeter.sh                                                                                                                                                                                            ✔ 
# --- /opt/apache-jmeter/bin/jmeter.sh: line 99: [: : integer expression expected
# --- /opt/apache-jmeter/bin/jmeter: line 128: [: : integer expression expected
# --- /opt/apache-jmeter/bin/jmeter: line 199: /usr/lib/jvm/java-22-openjdk/bin/java: No such file or directory
# -- system has Java 24 installed java-24-openjdk but JMeter is mistakenly trying to use java-22-openjdk
# --- export JAVA_HOME=/usr/lib/jvm/java-24-openjdk
# --- export PATH=$JAVA_HOME/bin:$PATH
