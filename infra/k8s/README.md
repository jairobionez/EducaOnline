# 📘 Documentação Técnica — Templates de Manifests do Kubernetes

Esta documentação descreve a organização, uso e procedimentos para implantação dos serviços da plataforma utilizando Kubernetes, tanto localmente (via Minikube) quanto em um cluster remoto.

---

## 📂 1. Visão Geral da Pasta de Manifests

A pasta contém *templates* de manifests Kubernetes usados para:

* Implantar serviços **backend**
* Implantar o **frontend**
* Facilitar deployments locais (Minikube) e em clusters reais

Cada serviço possui seus próprios manifests contendo:

* Deployments
* Services
* ConfigMaps/Secrets (quando aplicável)
* Probes de saúde
* Configurações de recursos

---

## 🧩 2. Como Utilizar os Templates

Antes do deployment:

1. Substitua todas as ocorrências de:

   <pre class="overflow-visible!" data-start="990" data-end="1017"><div class="contain-inline-size rounded-2xl relative bg-token-sidebar-surface-primary"><div class="sticky top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre!"><span><span>REPLACE_IMAGE</span><span>
   </span></span></code></div></div></pre>

   pela imagem Docker real, por exemplo:

   <pre class="overflow-visible!" data-start="1062" data-end="1104"><div class="contain-inline-size rounded-2xl relative bg-token-sidebar-surface-primary"><div class="sticky top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre!"><span><span>myregistry/servicename:1.0.0
   </span></span></code></div></div></pre>
2. Ajuste parâmetros importantes:

   * `replicas`
   * `resources.requests` / `resources.limits`
   * Variáveis de ambiente (`env`, `envFrom`)
   * Caminhos de *readiness* e *liveness* probes
3. Certifique-se de que cada API implementa um endpoint de saúde:

   * `/health`
   * `/health/ready`

     Ou atualize os paths das probes nos manifests.

---

## 🏗️ 3. Deployment Rápido com Minikube

### 3.1 Automatizado via PowerShell

Execute:

<pre class="overflow-visible!" data-start="1545" data-end="1633"><div class="contain-inline-size rounded-2xl relative bg-token-sidebar-surface-primary"><div class="sticky top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre! language-powershell"><span><span>powershell </span><span>-ExecutionPolicy</span><span> Bypass </span><span>-File</span><span> infra\k8s\</span><span>deploy-minikube</span><span>.ps1
</span></span></code></div></div></pre>

O script irá automaticamente:

* Construir imagens
* Carregar no Minikube
* Aplicar os manifests via kustomize

### 3.2 Manualmente

1. Inicie o Minikube:

   <pre class="overflow-visible!" data-start="1801" data-end="1849"><div class="contain-inline-size rounded-2xl relative bg-token-sidebar-surface-primary"><div class="sticky top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre! language-bash"><span><span>minikube start --driver=docker
   </span></span></code></div></div></pre>
2. Construa as imagens Docker e carregue no Minikube:

   <pre class="overflow-visible!" data-start="1908" data-end="2008"><div class="contain-inline-size rounded-2xl relative bg-token-sidebar-surface-primary"><div class="sticky top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre! language-powershell"><span><span>powershell </span><span>-ExecutionPolicy</span><span> Bypass </span><span>-File</span><span> infra\k8s\</span><span>build-and</span><span>-load-images</span><span>.ps1
   </span></span></code></div></div></pre>

   Ou:

   <pre class="overflow-visible!" data-start="2019" data-end="2069"><div class="contain-inline-size rounded-2xl relative bg-token-sidebar-surface-primary"><div class="sticky top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre! language-bash"><span><span>minikube image load <image-name>
   </span></span></code></div></div></pre>
3. Aplique os manifests via kustomize:

   <pre class="overflow-visible!" data-start="2113" data-end="2157"><div class="contain-inline-size rounded-2xl relative bg-token-sidebar-surface-primary"><div class="sticky top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre! language-bash"><span><span>kubectl apply -k infra/k8s
   </span></span></code></div></div></pre>
4. Para aplicar todos os YAML diretamente:

   <pre class="overflow-visible!" data-start="2205" data-end="2250"><div class="contain-inline-size rounded-2xl relative bg-token-sidebar-surface-primary"><div class="sticky top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre! language-bash"><span><span>kubectl apply -f infra/k8s/
   </span></span></code></div></div></pre>

---

## 🔧 4. Comandos Úteis do Kubernetes

### Pods

Listar pods do namespace `educaonline`:

<pre class="overflow-visible!" data-start="2345" data-end="2396"><div class="contain-inline-size rounded-2xl relative bg-token-sidebar-surface-primary"><div class="sticky top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre! language-bash"><span><span>kubectl get pods -n educaonline -o wide
</span></span></code></div></div></pre>

Excluir o namespace:

<pre class="overflow-visible!" data-start="2419" data-end="2467"><div class="contain-inline-size rounded-2xl relative bg-token-sidebar-surface-primary"><div class="sticky top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre! language-bash"><span><span>kubectl delete namespace educaonline
</span></span></code></div></div></pre>

### Services

Listar serviços:

<pre class="overflow-visible!" data-start="2499" data-end="2541"><div class="contain-inline-size rounded-2xl relative bg-token-sidebar-surface-primary"><div class="sticky top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre! language-bash"><span><span>kubectl get svc -n educaonline
</span></span></code></div></div></pre>

### Contextos

<pre class="overflow-visible!" data-start="2557" data-end="2596"><div class="contain-inline-size rounded-2xl relative bg-token-sidebar-surface-primary"><div class="sticky top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre! language-bash"><span><span>kubectl config get-contexts
</span></span></code></div></div></pre>

---

## 🌐 5. Exemplos de Deploy Manual no Kubernetes

Criar uma deployment simples (ex: Nginx):

<pre class="overflow-visible!" data-start="2695" data-end="2752"><div class="contain-inline-size rounded-2xl relative bg-token-sidebar-surface-primary"><div class="sticky top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre! language-bash"><span><span>kubectl create deployment nginx --image=nginx
</span></span></code></div></div></pre>

Expor a deployment:

<pre class="overflow-visible!" data-start="2774" data-end="2843"><div class="contain-inline-size rounded-2xl relative bg-token-sidebar-surface-primary"><div class="sticky top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre! language-bash"><span><span>kubectl expose deployment nginx --</span><span>type</span><span>=NodePort --port=80
</span></span></code></div></div></pre>

---

## 📦 6. Criando ConfigMaps

### 6.1 ConfigMap simples

<pre class="overflow-visible!" data-start="2905" data-end="2969"><div class="contain-inline-size rounded-2xl relative bg-token-sidebar-surface-primary"><div class="sticky top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre! language-bash"><span><span>kubectl create configmap nginx-config -n educaonline
</span></span></code></div></div></pre>

### 6.2 ConfigMap a partir de arquivo (ex.: nginx.conf)

Dentro de `/infra/nginx`:

<pre class="overflow-visible!" data-start="3054" data-end="3169"><div class="contain-inline-size rounded-2xl relative bg-token-sidebar-surface-primary"><div class="sticky top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre! language-bash"><span><span>kubectl create configmap nginx-config \
  --namespace educaonline \
  --from-file=nginx.conf=nginx.conf
</span></span></code></div></div></pre>

---

## 🔄 7. Reiniciando Recursos

Reiniciar uma deployment:

<pre class="overflow-visible!" data-start="3233" data-end="3300"><div class="contain-inline-size rounded-2xl relative bg-token-sidebar-surface-primary"><div class="sticky top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre! language-bash"><span><span>kubectl rollout restart deployment nginx -n educaonline
</span></span></code></div></div></pre>
