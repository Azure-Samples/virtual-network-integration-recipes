// -----------------------------------------------------------------------
// <copyright file="EventHubProcessor.cs" company="Microsoft Corporation">
// Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license. See LICENSE file in the project root for full license information.
// </copyright>
// -----------------------------------------------------------------------

namespace Recipes.AzureFunctions
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Text;
    using System.Threading.Tasks;
    using Azure.Messaging.EventHubs;
    using Microsoft.Azure.WebJobs;
    using Microsoft.Extensions.Logging;

    /// <summary>
    /// Azure function to process Event Hub message.
    /// </summary>
    public static class EventHubProcessor
    {
        /// <summary>
        /// Azure function main method.
        /// </summary>
        /// <param name="events">Event Hub message batch.</param>
        /// <param name="log">ILogger object to log message to Application insights.</param>
        /// <returns>A <see cref="Task"/> representing the asynchronous operation.</returns>
        [FunctionName("EventHubProcessor")]
        public static async Task Run([EventHubTrigger("%EventHubName%", Connection = "EventHubConnectionString")] EventData[] events, ILogger log)
        {
            var exceptions = new List<Exception>();

            foreach (EventData eventData in events)
            {
                try
                {
                    string messageBody = Encoding.UTF8.GetString(eventData.EventBody);
                    log.LogInformation($"C# Event Hub trigger function processed a message: {messageBody}");
                    await Task.Yield();
                }
                catch (Exception e)
                {
                    // Capture this exception and continue processing the rest of the batch.
                    exceptions.Add(e);
                }
            }

            // Once processing of the batch is complete, if any messages in the batch failed processing throw an exception so that there is a record of the failure.
            if (exceptions.Count > 1)
            {
                throw new AggregateException(exceptions);
            }

            if (exceptions.Count == 1)
            {
                throw exceptions.Single();
            }
        }
    }
}
