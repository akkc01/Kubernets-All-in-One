1 - sabse pahale node ke andar jayenge using-
    docker exec -it desktop-worker bash
    
    create make dir in node-
    mkdir Nodedata

2 - node pe leble set karenge-
    kubectl label nodes desktop-worker disktype=ssd

3 - ab aapko PV, PVC aur Deployment banana h.
4 - PV me hostpath ke path me node ka folder add kar denge-
     
      hostPath:
         path: /akkc

5 - Yaml files ko deply kar denge