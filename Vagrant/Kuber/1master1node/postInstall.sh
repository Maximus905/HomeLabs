# Helm install
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

#**********************

export K8S_USER=th2-adm
export POD_NETWORK='10.244.0.0/16'
export API_SEREVR_ADVERTISE_IP='192.168.1.62'

echo 'source <(kubectl completion bash)' >>~/.bashrc
sudo kubeadm init --pod-network-cidr=$POD_NETWORK --apiserver-advertise-address $API_SEREVR_ADVERTISE_IP
mkdir -p $HOME/.kube
sudo cp -n /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id $USER -u):$(id $USER -g) $HOME/.kube/config

#issue sert for user
openssl genrsa -out $K8S_USER.key 2048
openssl req -new -key $K8S_USER.key -out $K8S_USER.csr -subj "/CN=$K8S_USER"
openssl x509 -req -in $K8S_USER.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out $K8S_USER.crt -days 500
mkdir $USER/.certs
mv $K8S_USER.crt $K8S_USER.key $USER/.certs/
chown $(id $USER -u):$(id $USER -g) $USER/.certs/*

#install flannel
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/v0.14.0/Documentation/kube-flannel.yml
kubectl taint nodes --all node-role.kubernetes.io/master-
#kubectl taint node mymasternode node-role.kubernetes.io/master:NoSchedule-

cat <<EOF | sudo tee ${K8S_USER}_clusterRoleBinding.yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: $K8S_USER
  namespace: default
subjects:
- kind: User
  name: $K8S_USER
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOF
kubectl apply -f ${K8S_USER}_clusterRoleBinding.yaml

# join

