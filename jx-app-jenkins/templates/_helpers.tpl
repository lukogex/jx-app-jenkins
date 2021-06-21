{{/*
Returns configuration as code default config
*/}}
{{- define "jenkins.casc.defaults" -}}
jenkins:
  disableRememberMe: false
  remotingSecurity:
    enabled: true
  mode: NORMAL
  numExecutors: {{ .Values.master.numExecutors }}
  projectNamingStrategy: "standard"
  markupFormatter:
    {{- if .Values.master.enableRawHtmlMarkupFormatter }}
    rawHtml:
      disableSyntaxHighlighting: true
    {{- else }}
      "plainText"
    {{- end }}
  clouds:
  - kubernetes:
      containerCapStr: "{{ .Values.agent.containerCap }}"
      {{- if .Values.master.slaveKubernetesNamespace }}
      jenkinsTunnel: "{{ template "jenkins.fullname" . }}-agent.{{ template "jenkins.namespace" . }}:{{ .Values.master.slaveListenerPort }}"
      jenkinsUrl: "http://{{ template "jenkins.fullname" . }}.{{ template "jenkins.namespace" . }}:{{.Values.master.servicePort}}{{ default "" .Values.master.jenkinsUriPrefix }}"
      {{- else }}
      jenkinsTunnel: "{{ template "jenkins.fullname" . }}-agent:{{ .Values.master.slaveListenerPort }}"
      jenkinsUrl: "http://{{ template "jenkins.fullname" . }}:{{.Values.master.servicePort}}{{ default "" .Values.master.jenkinsUriPrefix }}"
      {{- end }}
      maxRequestsPerHostStr: "32"
      name: "kubernetes"
      namespace: "{{ template "jenkins.master.slaveKubernetesNamespace" . }}"
      serverUrl: "https://kubernetes.default"
      {{- if .Values.agent.enabled }}
      templates:
      - containers:
        - alwaysPullImage: {{ .Values.agent.alwaysPullImage }}
          {{- if .Values.agent.args }}
          args: "{{ .Values.agent.args }}"
          {{- else }}
          args: "^${computer.jnlpmac} ^${computer.name}"
          {{- end }}
          {{- if .Values.agent.command }}
          command: "{{ .Values.agent.command }}"
          {{- else }}
          command: "jenkins-slave"
          {{- end }}
          envVars:
          - containerEnvVar:
              key: "JENKINS_URL"
              value: "http://{{ template "jenkins.fullname" . }}.{{ template "jenkins.namespace" . }}.svc.{{.Values.clusterZone}}:{{.Values.master.servicePort}}{{ default "" .Values.master.jenkinsUriPrefix }}"
          {{- if .Values.agent.imageTag }}
          image: "{{ .Values.agent.image }}:{{ .Values.agent.imageTag }}"
          {{- else }}
          image: "{{ .Values.agent.image }}:{{ .Values.agent.tag }}"
          {{- end }}
          name: "{{ .Values.agent.sideContainerName }}"
          privileged: "{{- if .Values.agent.privileged }}true{{- else }}false{{- end }}"
          resourceLimitCpu: {{.Values.agent.resources.limits.cpu}}
          resourceLimitMemory: {{.Values.agent.resources.limits.memory}}
          resourceRequestCpu: {{.Values.agent.resources.requests.cpu}}
          resourceRequestMemory: {{.Values.agent.resources.requests.memory}}
          ttyEnabled: {{ .Values.agent.TTYEnabled }}
          workingDir: "/home/jenkins"
        idleMinutes: {{ .Values.agent.idleMinutes }}
        instanceCap: 2147483647
        {{- if .Values.agent.imagePullSecretName }}
        imagePullSecrets:
        - name: {{ .Values.agent.imagePullSecretName }}
        {{- end }}
        label: "{{ .Release.Name }}-{{ .Values.agent.componentName }}"
        name: "{{ .Values.agent.podName }}"
        nodeUsageMode: "NORMAL"
        podRetention: {{ .Values.agent.podRetention }}
        showRawYaml: true
        serviceAccount: "{{ include "jenkins.serviceAccountAgentName" . }}"
        slaveConnectTimeoutStr: "{{ .Values.agent.slaveConnectTimeout }}"
        yaml: |-
          {{ tpl .Values.agent.yamlTemplate . | nindent 10 | trim }}
        yamlMergeStrategy: "override"
      {{- end }}
  {{- if .Values.master.csrf.defaultCrumbIssuer.enabled }}
  crumbIssuer:
    standard:
      excludeClientIPFromCrumb: {{ if .Values.master.csrf.defaultCrumbIssuer.proxyCompatability }}true{{ else }}false{{- end }}
  {{- end }}
security:
  apiToken:
    creationOfLegacyTokenEnabled: false
    tokenGenerationOnCreationEnabled: false
    usageStatisticsEnabled: true
unclassified:
  location:
    adminAddress: {{ default "" .Values.master.jenkinsAdminEmail }}
    url: {{ template "jenkins.url" . }}
{{- end -}}

{{- define "jenkins.kubernetes-version" -}}
  {{- if .Values.master.installPlugins -}}
    {{- range .Values.master.installPlugins -}}
      {{ if hasPrefix "kubernetes:" . }}
        {{- $split := splitList ":" . }}
        {{- printf "%s" (index $split 1 ) -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

