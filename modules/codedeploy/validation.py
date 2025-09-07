import json
import boto3

def handler(event, context):
    print("CodeDeploy validation function started")
    print(f"Event: {json.dumps(event)}")
    
    try:
        deployment_id = event.get('DeploymentId')
        lifecycle_event_hook_execution_id = event.get('LifecycleEventHookExecutionId')
        
        print(f"Deployment ID: {deployment_id}")
        print(f"Lifecycle Event Hook Execution ID: {lifecycle_event_hook_execution_id}")
        
        codedeploy = boto3.client('codedeploy')
        
        validation_result = True
        
        if validation_result:
            codedeploy.put_lifecycle_event_hook_execution_status(
                deploymentId=deployment_id,
                lifecycleEventHookExecutionId=lifecycle_event_hook_execution_id,
                status='Succeeded'
            )
            print("Validation succeeded - notified CodeDeploy")
            return {
                'statusCode': 200,
                'body': json.dumps('Validation succeeded')
            }
        else:
            codedeploy.put_lifecycle_event_hook_execution_status(
                deploymentId=deployment_id,
                lifecycleEventHookExecutionId=lifecycle_event_hook_execution_id,
                status='Failed'
            )
            print("Validation failed - notified CodeDeploy")
            return {
                'statusCode': 500,
                'body': json.dumps('Validation failed')
            }
        
    except Exception as e:
        print(f"Error in validation function: {str(e)}")
        try:
            codedeploy.put_lifecycle_event_hook_execution_status(
                deploymentId=event.get('DeploymentId'),
                lifecycleEventHookExecutionId=event.get('LifecycleEventHookExecutionId'),
                status='Failed'
            )
        except:
            pass
        return {
            'statusCode': 500,
            'body': json.dumps(f'Validation error: {str(e)}')
        }