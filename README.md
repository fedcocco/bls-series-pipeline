# bls-series-pipeline

This pipeline regularly downloads data from the US Bureau of Labor Statistics (BLS) and uploads the data to S3. 

The file [series-data.csv](data/series-data.csv) contains the list of series ids that the pipeline downloads, along with additional metadata that is attached to the dataframe of results for each series. 

Each series is saved as a separate csv file in the `dist` folder using the file naming scheme `SERIESID.csv`, where `SERIESID` is the BLS id for the series shown in `series-data.csv.`

All of the files saved to the `dist` folder are automatically uploaded to S3 after the pipeline has run. They can be found at a URL with the following naming scheme, using the correct BLS id for each series. The id shown in this example is for total non-farm employment.

```
https://ft-ig-content-prod.s3-eu-west-1.amazonaws.com/v2/ft-interactive/bls-series-pipeline/main/CES0000000001.csv
```

This repo was created from the [circleci-pipeline-template]((https://github.com/ft-interactive/circleci-pipeline-template)). Please see the template repo to fiind the original setup instructions and links to resources on using the `targets` package.