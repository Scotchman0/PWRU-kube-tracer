#!/usr/bin/env bash
NODE=worker-0.sunbropwrutest.lab.upshift.rdu2.redhat.com
#args: pwru <options> <pcap filter>
#PWRU_ARGS="--output-tuple 'port 8080 and host $HOST'"
PORT="8080"
NAMESPACE=sunbro
#    args: ["-c", "pwru ${PWRU_ARGS}"]


#uncomment the below to allow ctrl+c to clear/remove the pod - currently commented to retain logs.
#trap " cleanup " EXIT

cleanup () {
  #kill all pwru pods created (not called currently)
  for i in $(oc get pod | grep pwru | awk {'print $1'}); do echo $i; oc delete pod $i --force; done
}

log_gather () {
  # get all pod logs from local storage for inspect (STDOUT pod logs rotate too fast)
  for i in $(oc get pod -n ${NAMESPACE} | grep -v NAME | grep "pwru-" |awk {'print $1'}); do echo $i; oc rsh $i sh -c "tar -czf export.tar.gz /tmp/*" ; oc cp ${i}:export.tar.gz ./${i}_export.tar.gz; done  
}

pwru_launcher() {

for i in $(oc get pod -n ${NAMESPACE} | grep -v NAME | awk {'print $1'}); 
  do 
  POD="$(echo $i)"; 
  HOST="$(oc get pod -n ${NAMESPACE} -o wide | grep $i | awk {'print $6'})";
#create the scraper pod:
oc apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: pwru-${POD}
  namespace: ${NAMESPACE}
spec:
  nodeSelector:
    kubernetes.io/hostname: ${NODE}
  containers:
  - image: quay.io/rhn_support_wrussell/pwru:latest
    name: pwru
    volumeMounts:
    - mountPath: /sys/kernel/debug
      name: sys-kernel-debug
    securityContext:
      privileged: true
    command: ["/bin/sh"]
    args: ["-c", "while true; do date >> /tmp/${HOST}.out; date; sleep 1; done & pwru --output-tuple 'port $PORT and host $HOST' | tee /tmp/${HOST}.out"]
  volumes:
  - name: sys-kernel-debug
    hostPath:
      path: /sys/kernel/debug
      type: DirectoryOrCreate
  hostNetwork: true
  hostPID: true
EOF


#validate pod start:
oc wait pod pwru --for condition=Ready --timeout=90s

done
}

if [ "$1" = --cleanup ];
  then 
    cleanup
  elif [ "$1" = "--pull-logs" ];
    then 
      log_gather
  else
    pwru_launcher
fi 