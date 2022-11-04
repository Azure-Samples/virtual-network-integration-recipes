// -----------------------------------------------------------------------
// <copyright file="WeatherForecast.cs" company="Microsoft Corporation">
// Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license. See LICENSE file in the project root for full license information.
// </copyright>
// -----------------------------------------------------------------------

namespace Recipes.AzureWebApps.WeatherForecastAPI
{
    using System;

    /// <summary>
    /// The weather forecast.
    /// </summary>
    public class WeatherForecast
    {
        /// <summary>
        /// Gets or sets the date of the weather forecast.
        /// </summary>
        public DateTime Date { get; set; }

        /// <summary>
        /// Gets or sets the temperature in Celsius of the weather forecast.
        /// </summary>
        public int TemperatureC { get; set; }

        /// <summary>
        /// Gets the temperature in Fahrenheit of the weather forecast (calcuated from the Celsius temperature).
        /// </summary>
        public int TemperatureF => 32 + (int)(this.TemperatureC / 0.5556);

        /// <summary>
        /// Gets or sets a text summary of the weather forecast.
        /// </summary>
        public string Summary { get; set; }
    }
}
