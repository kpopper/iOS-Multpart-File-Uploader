/*
 * Copyright 2010-2012 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */
#import "SecurityTokenServiceGetSessionTokenResponse.h"
#import "SecurityTokenServiceGetSessionTokenResponseUnmarshaller.h"
#import "SecurityTokenServiceGetSessionTokenRequest.h"
#import "SecurityTokenServiceGetSessionTokenRequestMarshaller.h"
#import "SecurityTokenServiceGetFederationTokenResponse.h"
#import "SecurityTokenServiceGetFederationTokenResponseUnmarshaller.h"
#import "SecurityTokenServiceGetFederationTokenRequest.h"
#import "SecurityTokenServiceGetFederationTokenRequestMarshaller.h"

#import "../AmazonWebServiceClient.h"

/** \defgroup SecurityTokenService AWS Security Token Service */

/** <summary>
 * Interface for accessing AmazonSecurityTokenService.
 *
 *  AWS Security Token Service <p>
 * The AWS Security Token Service is a web service that enables you to request temporary, limited-privilege credentials for AWS Identity and Access Management (IAM) users or for users that you
 * authenticate (federated users). This guide provides descriptions of the AWS Security Token Service API.
 * </p>
 * <p>
 * For more detailed information about using this service, go to <a href="http://docs.amazonwebservices.com/IAM/latest/UsingSTS/Welcome.html"> Using Temporary Security Credentials </a> .
 * </p>
 * <p>
 * For information about setting up signatures and authorization through the API, go to <a href="http://docs.amazonwebservices.com/general/latest/gr/signing_aws_api_requests.html"> Signing AWS API
 * Requests </a> in the <i>AWS General Reference</i> . For general information about the Query API, go to <a href="http://docs.amazonwebservices.com/IAM/latest/UserGuide/IAM_UsingQueryAPI.html"> Making
 * Query Requests </a> in <i>Using IAM</i> . For information about using security tokens with other AWS products, go to <a href="http://docs.amazonwebservices.com/IAM/latest/UsingSTS/UsingTokens.html">
 * Using Temporary Security Credentials to Access AWS </a> in <i>Using Temporary Security Credentials</i> .
 * </p>
 * <p>
 * If you're new to AWS and need additional technical information about a specific AWS product, you can find the product's technical documentation at <a href="http://aws.amazon.com/documentation/">
 * http://aws.amazon.com/documentation/ </a> .
 * </p>
 * <p>
 * We will refer to Amazon Identity and Access Management using the abbreviated form IAM. All copyrights and legal protections still apply.
 * </p>
 * </summary>
 *
 */
@interface AmazonSecurityTokenServiceClient:AmazonWebServiceClient
{
}


/**
 * <p>
 * The GetSessionToken action returns a set of temporary credentials for an AWS account or IAM user. The credentials
 * consist of an Access Key ID, a Secret Access Key, and a security token. These credentials are valid for the specified
 * duration only. The session duration for IAM users can be between one and 36 hours, with a default of 12 hours. The
 * session duration for AWS account owners is restricted to one hour. Providing the AWS Multi-Factor Authentication (MFA)
 * device serial number and the token code is optional.
 * </p>
 * <p>
 * For more information about using GetSessionToken to create temporary credentials, go to <a
 * href="http://docs.amazonwebservices.com/IAM/latest/UserGuide/CreatingSessionTokens.html"> Creating Temporary Credentials
 * to Enable Access for IAM Users </a> in <i>Using IAM</i> .
 * </p>
 *
 * @param getSessionTokenRequest Container for the necessary parameters to execute the GetSessionToken service method on
 *           AmazonSecurityTokenService.
 *
 * @return The response from the GetSessionToken service method, as returned by AmazonSecurityTokenService.
 *
 *
 * @exception AmazonClientException If any internal errors are encountered inside the client while
 * attempting to make the request or handle the response.  For example
 * if a network connection is not available.  For more information see <AmazonClientException>.
 * @exception AmazonServiceException If an error response is returned by AmazonSecurityTokenService indicating
 * either a problem with the data in the request, or a server side issue.  For more information see <AmazonServiceException>.
 *
 * @see SecurityTokenServiceGetSessionTokenRequest
 * @see SecurityTokenServiceGetSessionTokenResponse
 */
-(SecurityTokenServiceGetSessionTokenResponse *)getSessionToken:(SecurityTokenServiceGetSessionTokenRequest *)getSessionTokenRequest;


/**
 * <p>
 * The GetFederationToken action returns a set of temporary credentials for a federated user with the user name and policy
 * specified in the request. The credentials consist of an Access Key ID, a Secret Access Key, and a security token.
 * Credentials created by IAM users are valid for the specified duration, between one and 36 hours; credentials created
 * using account credentials last one hour.
 * </p>
 * <p>
 * The federated user who holds these credentials has any permissions allowed by the intersection of the specified policy
 * and any resource or user policies that apply to the caller of the GetFederationToken API, and any resource policies that
 * apply to the federated user's Amazon Resource Name (ARN). For more information about how token permissions work, see <a
 * href="http://docs.amazonwebservices.com/IAM/latest/UserGuide/TokenPermissions.html"> Controlling Permissions in
 * Temporary Credentials </a> in <i>Using AWS Identity and Access Management</i> . For information about using
 * GetFederationToken to create temporary credentials, see <a
 * href="http://docs.amazonwebservices.com/IAM/latest/UserGuide/CreatingFedTokens.html"> Creating Temporary Credentials to
 * Enable Access for Federated Users </a> in <i>Using AWS Identity and Access Management</i> .
 * </p>
 *
 * @param getFederationTokenRequest Container for the necessary parameters to execute the GetFederationToken service method
 *           on AmazonSecurityTokenService.
 *
 * @return The response from the GetFederationToken service method, as returned by AmazonSecurityTokenService.
 *
 * @exception SecurityTokenServicePackedPolicyTooLargeException For more information see <SecurityTokenServicePackedPolicyTooLargeException>
 * @exception SecurityTokenServiceMalformedPolicyDocumentException For more information see <SecurityTokenServiceMalformedPolicyDocumentException>
 *
 * @exception AmazonClientException If any internal errors are encountered inside the client while
 * attempting to make the request or handle the response.  For example
 * if a network connection is not available.  For more information see <AmazonClientException>.
 * @exception AmazonServiceException If an error response is returned by AmazonSecurityTokenService indicating
 * either a problem with the data in the request, or a server side issue.  For more information see <AmazonServiceException>.
 *
 * @see SecurityTokenServiceGetFederationTokenRequest
 * @see SecurityTokenServiceGetFederationTokenResponse
 */
-(SecurityTokenServiceGetFederationTokenResponse *)getFederationToken:(SecurityTokenServiceGetFederationTokenRequest *)getFederationTokenRequest;



@end

