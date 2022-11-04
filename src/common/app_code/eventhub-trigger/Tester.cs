// -----------------------------------------------------------------------
// <copyright file="Tester.cs" company="Microsoft Corporation">
// Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license. See LICENSE file in the project root for full license information.
// </copyright>
// -----------------------------------------------------------------------
namespace Recipes.AzureFunctions
{
    using System;
    using Microsoft.Azure.WebJobs;
    using Microsoft.Extensions.Logging;

    /// <summary>
    /// Azure function to send a test Event Hub message and verify that the workflow executes successfully.
    /// </summary>
    public static class Tester
    {
        /// <summary>
        /// Azure function main method.
        /// </summary>
        /// <param name="myTimer">Event Hub message batch.</param>
        /// <param name="log">ILogger object to log message to Application insights.</param>
        /// <returns>A <see cref="string"/> representing the message content.</returns>
        [FunctionName("Tester")]
        [return: EventHub("%EventHubName%", Connection = "EventHubConnectionString")]
        public static string Run([TimerTrigger("0 * * * * *")] TimerInfo myTimer, ILogger log)
        {
            log.LogInformation($"C# Timer trigger function executed at: {DateTime.Now}");
            return "Test Message";
        }
    }
}
