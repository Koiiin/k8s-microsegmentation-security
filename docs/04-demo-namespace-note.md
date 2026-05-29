\# Demo Namespace Note



`microseg-demo` is a lightweight demonstration namespace used to validate Kubernetes micro-segmentation, Hubble observability, NetworkPolicy enforcement, and Falco runtime detection before building the complete application workload.



This namespace is not the final business application. It is intentionally simple and includes:



| Workload | Purpose |

|---|---|

| `client-netshoot` | Legitimate client used to generate allowed traffic |

| `backend-nginx` | Backend service deployed on a different worker node |

| `attacker-netshoot` | Untrusted pod used to validate denied traffic and runtime detection |



The namespace is used to prove the following security controls:



1\. Pod-to-pod communication across worker nodes.

2\. Default-deny NetworkPolicy enforcement.

3\. Explicit allow policy based on pod labels.

4\. Hubble visibility for forwarded and dropped flows.

5\. Falco detection of suspicious runtime behavior such as shell execution inside a container.



A complete application workload, such as a Voting App or a multi-tier microservices application, can be added later after the security controls are validated.

