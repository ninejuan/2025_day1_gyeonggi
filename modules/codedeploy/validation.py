import json
import boto3

def handler(event, context):
    print("CodeDeploy validation function started")
    print(f"Event: {json.dumps(event)}")
    
    try:
        # CodeDeploy에서 전달받은 deployment ID와 lifecycle event hook execution ID
        deployment_id = event.get('DeploymentId')
        lifecycle_event_hook_execution_id = event.get('LifecycleEventHookExecutionId')
        
        print(f"Deployment ID: {deployment_id}")
        print(f"Lifecycle Event Hook Execution ID: {lifecycle_event_hook_execution_id}")
        
        # CodeDeploy 클라이언트 생성
        codedeploy = boto3.client('codedeploy')
        
        # 검증 로직 (여기서는 항상 성공)
        validation_result = True
        
        if validation_result:
            # 성공 시 CodeDeploy에 성공 상태 전달
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
            # 실패 시 CodeDeploy에 실패 상태 전달
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
        # 오류 발생 시에도 CodeDeploy에 알림
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