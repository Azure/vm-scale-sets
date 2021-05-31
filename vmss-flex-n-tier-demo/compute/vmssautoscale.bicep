param vmssId string
param autoscalename string = 'autoscaler'
param autoscaleenabled bool = false
param autoScaleMin string = '1'
param autoScaleMax string = '10'
param autoScaleDefault string = '5'
param durationInMinutes int = 10
param scaleOutCPUPercentageThreshold int = 75
param scaleOutInterval string = '1'
param scaleInCPUPercentageThreshold int = 25
param scaleInInterval string = '1'


var oneMin = 'PT1M' 

resource autoscale 'Microsoft.insights/autoscalesettings@2015-04-01' = {
  name: autoscalename
  location: resourceGroup().location
  properties: {
    targetResourceUri: vmssId
    enabled: autoscaleenabled
    profiles:[
      {
        name: 'Profile1'
        capacity: {
          minimum: autoScaleMin
          maximum: autoScaleMax
          default: autoScaleDefault
        }
        rules: [
          {
            metricTrigger:{
              metricName: 'Percentage CPU'
              metricNamespace: ''
              metricResourceUri: vmssId
              statistic: 'Average'
              timeGrain: oneMin
              timeWindow: 'PT${durationInMinutes}M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: scaleOutCPUPercentageThreshold
            }
            scaleAction: {
              direction:'Increase'
              type: 'ChangeCount'
              value: scaleOutInterval
              cooldown: oneMin
            }
          }
          {
            metricTrigger:{
              metricName: 'Percentage CPU'
              metricNamespace: ''
              metricResourceUri: vmssId
              statistic: 'Average'
              timeGrain: oneMin
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: scaleInCPUPercentageThreshold
            }
            scaleAction: {
              direction:'Decrease'
              type: 'ChangeCount'
              value: scaleInInterval
              cooldown: oneMin
            }
          }
        ]
      }
    ]
  }
}

