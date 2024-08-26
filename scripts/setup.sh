#! /bin/bash -f

sudo apt-get update

#Install packages to allow apt to use a repository over HTTPS:
sudo apt-get install -y apt-transport-https \
	                ca-certificates \
		        curl \
		        software-properties-common \
				jq \
				conntrack \

#Add Docker’s official GPG key:

# Add Docker's official GPG key:
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
#install kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.18.0/bin/linux/amd64/kubectl

#Make the kubectl binary executable.
chmod +x ./kubectl

#Move the binary in to your PATH.
sudo mv ./kubectl /usr/bin/kubectl

echo "source <(kubectl completion bash)" >> ~/.bashrc

sudo usermod -aG docker $USER 

sudo curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | TAG=v4.0.0 bash

sudo k3d cluster create training -c cluster.yaml
sudo mkdir $HOME/.kube
sudo chown -R $USER $HOME/.kube
k3d kubeconfig get training > $HOME/.kube/config


#install kube-ps1
cd ~/
git clone https://github.com/jonmosco/kube-ps1.git
echo 'source ~/kube-ps1/kube-ps1.sh' >> ~/.bashrc
echo "PS1='[\u@\h \W \$(kube_ps1)]\$ '" >> ~/.bashrc
cd -

#install kubens and kubectx
git clone https://github.com/ahmetb/kubectx.git ~/.kubectx
COMPDIR=/usr/share/bash-completion/completions
sudo ln -sf ~/.kubectx/completion/kubens.bash $COMPDIR/kubens
sudo ln -sf ~/.kubectx/completion/kubectx.bash $COMPDIR/kubectx
cat << FOE >> ~/.bashrc


#kubectx and kubens
export PATH=~/.kubectx:\$PATH
FOE