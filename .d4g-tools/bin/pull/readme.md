# Install gum

```
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt update && sudo apt install gum
```

# Content of cron file on sytem:


```bash
* * * * * /opt/d4g/12_taxobservatory_dataviz_dev/.d4g-tools/deploy/pull/pull_cron.sh --repository-name=dataforgoodfr/12_taxobservatory_dataviz_dev --branch=dev >> /opt/d4g/12_taxobservatory_dataviz_dev/pull_cron.log 2>&1
```
