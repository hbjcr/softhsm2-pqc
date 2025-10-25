Inspired by:
- [https://github.com/vegardit/docker-softhsm2-pkcs11-proxy](https://github.com/vegardit/docker-softhsm2-pkcs11-proxy)
- [https://github.com/miekg/pkcs11](https://github.com/miekg/pkcs11)
- [https://github.com/kingcdavid/pkcs11-mldsa](https://github.com/kingcdavid/pkcs11-mldsa)

Test ML-DSA key creation:

docker run \
    --name softhsm-pqc \
    --user $(id -u):$(id -g) \
    -e TEST_KEY_GEN='true' \
    hbjcr/softhsm2-pqc:latest 
