/**
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License.
 */

using System.Threading.Tasks;

namespace csharp
{
   public static class TaskExtensions
   {
      /* TaskStatus enum
         * Created, = 0
         * WaitingForActivation, = 1
         * WaitingToRun, = 2
         * Running, = 3
         * WaitingForChildrenToComplete, = 4
         * RanToCompletion, = 5
         * Canceled, = 6
         * Faulted = 7  */
      public static bool IsNullFinishCanceledOrFaulted(this Task task) => task == null || (int)task.Status >= 5;
   }
}
