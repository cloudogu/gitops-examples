# GitOps Examples

This repository serves as a direct companion to the [GitOps Playground](https://github.com/cloudogu/gitops-playground) from Cloudogu. It contains example configurations to test and showcase 

## What will you find here?

In this repo, we collect various templates and configurations tailored to be used with the gitops-playground. Typically this includes:

* configurations for gop features
* example Jenkins Pipelines
* multi-tenant gop configurations


## What does each example do?

### example-apps-via-content-loader
```mermaid
graph TD
    subgraph ArgoCD_Namespace [ArgoCD Namespace]
        App_Root[ArgoCD Application: example-apps]
        Proj_Root[ArgoCD AppProject: example-apps]
        
        App_PH_S[ArgoCD Application: petclinic-helm-staging]
        App_PH_P[ArgoCD Application: petclinic-helm-production]
        App_PP_S[ArgoCD Application: petclinic-plain-staging]
        App_PP_P[ArgoCD Application: petclinic-plain-production]
    end

    App_Root --> App_PH_S
    App_Root --> App_PH_P
    App_Root --> App_PP_S
    App_Root --> App_PP_P
    
    App_PH_S -.-> NS_S[Namespace: example-apps-staging]
    App_PH_P -.-> NS_P[Namespace: example-apps-production]
    App_PP_S -.-> NS_S
    App_PP_P -.-> NS_P

    subgraph Staging_Namespace [Staging Namespace]
        PP_S_Deploy[Deployment: spring-petclinic-plain]
        PP_S_Svc[Service: spring-petclinic-plain]
        PP_S_Ing[Ingress: spring-petclinic-plain]
        
        PH_S_Deploy[Deployment: spring-petclinic-helm]
        PH_S_CM[ConfigMap: messages]
        PH_S_Sec[Secrets]
    end

    subgraph Production_Namespace [Production Namespace]
        PP_P_Deploy[Deployment: spring-petclinic-plain]
        PP_P_Svc[Service: spring-petclinic-plain]
        PP_P_Ing[Ingress: spring-petclinic-plain]
        
        PH_P_Deploy[Deployment: spring-petclinic-helm]
        PH_P_CM[ConfigMap: messages]
        PH_P_Sec[Secrets]
    end

    %% Documentation Links
    App_PP_S --> PP_S_Deploy
    App_PP_S --> PP_S_Svc
    App_PP_S --> PP_S_Ing
    
    App_PH_S --> PH_S_Deploy
    App_PH_S --> PH_S_CM
    App_PH_S --> PH_S_Sec
```

### init-multi-tenancy
```mermaid
graph TD
    subgraph Management_Cluster [Management Cluster / ArgoCD]
        AS[ApplicationSet: gop-multi-tenancy]
        T1_Config[tenant-configs.git: tenants/tenant1/config.yaml]
    end

    AS -- "Git Generator" --> T1_Config
    AS -- "Template" --> T1_App[ArgoCD Application: gop-tenant-tenant1]

    subgraph Tenant1_Instance [Tenant 1 Lifecycle]
        T1_App -- "Deploys" --> GOP_Chart[GOP Helm Chart]
        GOP_Chart -- "Creates" --> GOP_Pod[GOP Operator Pod]
        
        subgraph Tenant1_Resources [Resources managed by Tenant 1 GOP]
            GOP_Pod --> Jenkins[Jenkins]
            GOP_Pod --> ArgoCD_T1[ArgoCD]
            GOP_Pod --> Registry_T1[Registry]
            
            subgraph Tenant1_Content [Tenant 1 Content]
                ArgoCD_T1 --> Petclinic[Petclinic Apps]
                ArgoCD_T1 --> Libs[Build Libraries]
            end
        end
    end

    %% Relationships
    T1_App -.->|Namespace: argocd| Management_Cluster
    GOP_Pod -.->|Reads| T1_Config
```

## Useful Links
* [GitOps Playground Repository](https://github.com/cloudogu/gitops-playground)
* [Cloudogu Website](https://cloudogu.com/)
