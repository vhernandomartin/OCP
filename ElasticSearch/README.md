

## Cluster Status
#### How to check the cluster status

> oc exec -c elasticsearch <ES_POD_NAME> -- curl -s /etc/elasticsearch/secret/admin-ca https://localhost:9200/_cat/health?h=status

In order to simplify curl operations with ElasticSearch export the following variable to use curl with required ES certs and pointing to the required ES port.

```
# export curl_es='curl -s --max-time 5 --key /etc/elasticsearch/secret/admin-key --cert /etc/elasticsearch/secret/admin-cert --cacert /etc/elasticsearch/secret/admin-ca https://localhost:9200'
```

Example:
```
# oc exec -c elasticsearch logging-es-data-master-98ys8mq6-2-7rq9m -- $curl_es/_cat/health?h=status

green
```
## Indices
#### How to check the Indices status

```
# oc exec -c elasticsearch logging-es-data-master-98ys8mq6-2-7rq9m -- $curl_es/_cat/indices?v\&bytes=m

health status index                                                                uuid                   pri rep docs.count docs.deleted store.size pri.store.size
green  open   project.newtesthttpd.9092fe0d-459c-11e9-8a24-525400451bb0.2019.04.30 mE86f3WMTkih3EshE0hV9A   1   1        125            0          0              0
green  open   .kibana.d033e22ae348aeb5660fc2140aec35850c4da997                     9gOhRz9XR3qAP0kPe6C8xw   1   0          5            0          0              0
green  open   .kibana                                                              lbD_hrxRReWxoib7aaySiw   1   1          1            0          0              0
green  open   .operations.2019.04.30                                               z5dPmgX2T2e-PcTb8ecgYQ   1   1      53230            0        113             57
green  open   .searchguard                                                         DhoZ_64VRwy4M5nR9uwh1Q   1   1          5            1          0              0
green  open   .operations.2019.04.26                                               Vf-3GiKFQQSegsMdiKbhUw   1   1     177121            0        316            158

```

#### How to add replica to Indices
Run a PUT request with curl to change the replica settings on specific index.

Example (Here, .kibana.xxxxx is our index to be replicated):
```
# oc exec -c elasticsearch logging-es-data-master-98ys8mq6-2-7rq9m -- curl -s --max-time 5 --key /etc/elasticsearch/secret/admin-key --cert /etc/elasticsearch/secret/admin-cert --cacert /etc/elasticsearch/secret/admin-ca -XPUT 'https://localhost:9200/.kibana.d033e22ae348aeb5660fc2140aec35850c4da997/_settings' -d '
{
  "index": {
    "number_of_replicas" : 1
  }
}'
```
